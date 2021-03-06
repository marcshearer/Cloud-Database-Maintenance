//
//  iCloud.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 22/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class ICloud {
    
    private var cancelRequest = false
    
    public func cancel() {
        self.cancelRequest = true
    }
    
    public func download(recordType: String,
                         database: CKDatabase? = nil,
                         keys: [String]! = nil,
                         sortKey: [String]! = nil,
                         sortAscending: Bool! = true,
                         predicate: NSPredicate = NSPredicate(value: true),
                         resultsLimit: Int! = nil,
                         downloadAction: ((CKRecord) -> ())? = nil,
                         completeAction: (() -> ())? = nil,
                         failureAction:  ((String) -> ())? = nil,
                         cursor: CKQueryCursor! = nil,
                         rowsRead: Int = 0) {
        
        var queryOperation: CKQueryOperation
        var rowsRead = rowsRead
        // Clear cancel flag
        self.cancelRequest = false
        
        // Fetch player records from cloud
        let cloudContainer = CKContainer(identifier: Config.iCloudIdentifier)
        let publicDatabase = database ?? cloudContainer.publicCloudDatabase
        if cursor == nil {
            // First time in - set up the query
            let query = CKQuery(recordType: recordType, predicate: predicate)
            if sortKey != nil {
                var sortDescriptor: [NSSortDescriptor] = []
                for sortKeyElement in sortKey {
                    sortDescriptor.append(NSSortDescriptor(key: sortKeyElement, ascending: sortAscending ?? true))
                }
                query.sortDescriptors = sortDescriptor
            }
            queryOperation = CKQueryOperation(query: query)
        } else {
            // Continue previous query
            queryOperation = CKQueryOperation(cursor: cursor)
        }
        queryOperation.desiredKeys = keys
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = (resultsLimit != nil ? resultsLimit : (rowsRead < 100 ? 20 : 100))
        queryOperation.recordFetchedBlock = { (record) -> Void in
            let cloudObject: CKRecord = record
            rowsRead += 1
            downloadAction?(cloudObject)
        }
        
        queryOperation.queryCompletionBlock = { (cursor, error) -> Void in
            if error != nil {
                failureAction?("Unable to fetch records for \(recordType) - \(error?.localizedDescription ?? "")")
                return
            }
            
            if cursor != nil && !self.cancelRequest && (resultsLimit == nil || rowsRead < resultsLimit) {
                // More to come - recurse
                _ = self.download(recordType: recordType,
                                  database: database,
                                  keys: keys,
                                  sortKey: sortKey,
                                  sortAscending: sortAscending,
                                  predicate: predicate,
                                  resultsLimit: resultsLimit,
                                  downloadAction: downloadAction,
                                  completeAction: completeAction,
                                  failureAction: failureAction,
                                  cursor: cursor, rowsRead: rowsRead)
            } else {
                completeAction?()
            }
        }
        
        // Execute the query - disable
        publicDatabase.add(queryOperation)
    }
    
    public func update(records: [CKRecord]? = nil, recordIDsToDelete: [CKRecord.ID]? = nil, database: CKDatabase? = nil, recordsRemainder: [CKRecord]? = nil, recordIDsToDeleteRemainder: [CKRecord.ID]? = nil, completion: ((Error?)->())? = nil) {
        // Copes with limit being exceeed which splits the load in two and tries again
        var lastSplit = 400
        
        if (records?.count ?? 0) + (recordIDsToDelete?.count ?? 0) > lastSplit {
            // No point trying - split immediately
            lastSplit = self.updatePortion(database: database, requireLess: true, lastSplit: lastSplit, records: records, recordIDsToDelete: recordIDsToDelete, recordsRemainder: recordsRemainder, recordIDsToDeleteRemainder: recordIDsToDeleteRemainder, completion: completion)
        } else {
            // Give it a go
            let cloudContainer = CKContainer.init(identifier: Config.iCloudIdentifier)
            let database = database ?? cloudContainer.publicCloudDatabase
            
            let uploadOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordIDsToDelete)
            
            uploadOperation.isAtomic = true
            uploadOperation.database = database
            
            // Assign a completion handler
            uploadOperation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecords: [CKRecord.ID]?, error: Error?) -> Void in
                if error != nil {
                    if let error = error as? CKError {
                        if error.code == .limitExceeded {
                            // Limit exceeded - start at 400 and then split in two and try again
                            lastSplit = self.updatePortion(database: database, requireLess: true, lastSplit: lastSplit, records: records, recordIDsToDelete: recordIDsToDelete, recordsRemainder: recordsRemainder, recordIDsToDeleteRemainder: recordIDsToDeleteRemainder, completion: completion)
                        } else if error.code == .partialFailure {
                            completion?(error)
                        } else {
                            completion?(error)
                        }
                    } else {
                        completion?(error)
                    }
                } else {
                    if recordsRemainder != nil || recordIDsToDeleteRemainder != nil {
                        // Now need to send next block of records
                        lastSplit = self.updatePortion(database: database, requireLess: false, lastSplit: lastSplit, records: nil, recordIDsToDelete: nil, recordsRemainder: recordsRemainder, recordIDsToDeleteRemainder: recordIDsToDeleteRemainder, completion: completion)
                        
                    } else {
                        completion?(nil)
                    }
                }
            }
            
            // Add the operation to an operation queue to execute it
            OperationQueue().addOperation(uploadOperation)
        }
    }
    
    private func updatePortion(database: CKDatabase?, requireLess: Bool, lastSplit: Int, records: [CKRecord]?, recordIDsToDelete: [CKRecord.ID]?, recordsRemainder: [CKRecord]?, recordIDsToDeleteRemainder: [CKRecord.ID]?, completion: ((Error?)->())?) -> Int {
        
        // Limit exceeded - start at 400 and then split in two and try again

        // Join records and remainder back together again
        var allRecords = records ?? []
        if recordsRemainder != nil {
            allRecords += recordsRemainder!
        }
        var allRecordIDsToDelete = recordIDsToDelete ?? []
        if recordIDsToDeleteRemainder != nil {
            allRecordIDsToDelete += recordIDsToDeleteRemainder!
        }

        var split = lastSplit
        let firstTime = (recordsRemainder == nil && recordIDsToDeleteRemainder == nil)
        if requireLess {
            if allRecords.count != 0 {
                // Split the records
                let half = Int((records?.count ?? 0) / 2)
                split = (firstTime ? lastSplit : half)
            } else {
                // Split the record IDs to delete
                let half = Int((recordIDsToDelete?.count ?? 0) / 2)
                split = (firstTime ? lastSplit : half)
            }
        } else {
            split = lastSplit
        }
        
        // Now split at new break point
        if allRecords.count != 0 {
            split = min(split, allRecords.count)
            let firstBlock = Array(allRecords.prefix(upTo: split))
            let secondBlock = (allRecords.count <= split ? nil : Array(allRecords.suffix(from: split)))
            self.update(records: firstBlock, database: database, recordsRemainder: secondBlock, recordIDsToDeleteRemainder: allRecordIDsToDelete, completion: completion)
        } else {
            split = min(split, allRecordIDsToDelete.count)
            let firstBlock = Array(allRecordIDsToDelete.prefix(upTo: split))
            let secondBlock = (allRecordIDsToDelete.count <= split ? nil : Array(allRecordIDsToDelete.suffix(from: split)))
            self.update(recordIDsToDelete: firstBlock, database: database, recordIDsToDeleteRemainder: secondBlock, completion: completion)
        }
        
        return split
    }

    
    public func backup(recordType: String, groupName: String, elementName: String, sortKey: [String]? = nil, sortAscending: Bool? = nil, directory: [String], completion: @escaping (Bool, String)->()) {
        var records = 0
        var errorMessage = ""
        var ok = true
        
        
        if let fileHandle = openFile(directory: directory, recordType: recordType) {
            self.writeString(fileHandle: fileHandle, string: "{ \(groupName) : {\n")
            _ = self.download(recordType: recordType,
                              sortKey: sortKey,
                              sortAscending: sortAscending,
                              downloadAction: { (record) in
                                records += 1
                                if records > 1 {
                                    self.writeString(fileHandle: fileHandle, string: ",\n")
                                }
                                self.writeString(fileHandle: fileHandle, string: "     \(elementName) : ")
                                if !self.writeRecord(fileHandle: fileHandle, elementName: elementName, record: record) {
                                    errorMessage = "Error writing record"
                                    ok = false
                                }
            },
                              completeAction: {
                                self.writeString(fileHandle: fileHandle, string: "\n     }")
                                self.writeString(fileHandle: fileHandle, string: "\n}")
                                fileHandle.closeFile()
                                completion(ok, (ok ? "Successfully backed up \(records) \(recordType)" : (errorMessage != "" ? errorMessage : "Unexpected error")))
            },
                              failureAction: { (message) in
                                fileHandle.closeFile()
                                errorMessage = "Error downloading \(recordType) (\(message))"
                                completion(false, errorMessage)
            })
        } else {
            completion(false, "Error creating backup file")
        }
    }
    
    public func getDatabaseIdentifier(completion: @escaping (Bool, String?, String?)->()) {
        var database: String!
        
        _ = self.download(recordType: "Version",
                          downloadAction: { (record) in
                                database = Utility.objectString(cloudObject: record, forKey: "database")
                          },
                          completeAction: {
                                completion(true, nil, database)
                          },
                          failureAction: { (message) in
                                completion(false, message, nil)
                          })
    }
    
    private func openFile(directory: [String], recordType: String) -> FileHandle! {
        var fileHandle: FileHandle!
        
        let dirUrl:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
        var subDirUrl = dirUrl
        for subDir in directory {
            subDirUrl = subDirUrl.appendingPathComponent(subDir)
        }
        let fileUrl =  subDirUrl.appendingPathComponent("\(recordType).json")
        let fileManager = FileManager()
        do {
            try fileManager.createDirectory(at: subDirUrl, withIntermediateDirectories: true)
        } catch {
        }
        fileManager.createFile(atPath: fileUrl.path, contents: nil)
        fileHandle = FileHandle(forWritingAtPath: fileUrl.path)
        
        return fileHandle
    }
    
    private func writeRecord(fileHandle: FileHandle, elementName: String, record: CKRecord) -> Bool {
        // Build a dictionary from the record
        var dictionary: [String : String] = [:]
        
        for key in record.allKeys() {
            let value = Utility.objectAsString(cloudObject: record, forKey: key)
            dictionary[key] = value
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            // error
            return false
        }
        fileHandle.write(data)
        return true
    }
    
    private func writeString(fileHandle: FileHandle, string: String) {
        let data = string.data(using: .utf8)!
        fileHandle.write(data)
    }
    
    public func errorMessage(_ error: Error?) -> String {
        if error == nil {
            return "Success"
        } else {
            if let ckError = error as? CKError {
                return "Error updating (\(ckError.localizedDescription))"
            } else {
                return "Error updating (\(error!.localizedDescription))"
            }
        }
    }
}
