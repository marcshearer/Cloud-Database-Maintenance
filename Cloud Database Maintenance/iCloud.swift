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
                         keys: [String]! = nil,
                         sortKey: String! = nil,
                         sortAscending: Bool = true,
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
        let cloudContainer = CKContainer(identifier: "iCloud.MarcShearer.Contract-Whist-Scorecard")
        let publicDatabase = cloudContainer.publicCloudDatabase
        if cursor == nil {
            // First time in - set up the query
            let query = CKQuery(recordType: recordType, predicate: predicate)
            if sortKey != nil {
                let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: sortAscending)
                query.sortDescriptors = [sortDescriptor]
            }
            queryOperation = CKQueryOperation(query: query)
        } else {
            // Continue previous query
            queryOperation = CKQueryOperation(cursor: cursor)
        }
        queryOperation.desiredKeys = keys
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = (resultsLimit != nil ? resultsLimit : (rowsRead < 100 ? 30 : 100))
        queryOperation.recordFetchedBlock = { (record) -> Void in
            let cloudObject: CKRecord = record
            rowsRead += 1
            downloadAction?(cloudObject)
        }
        
        queryOperation.queryCompletionBlock = { (cursor, error) -> Void in
            if error != nil {
                failureAction?("Unable to fetch records from \(recordType) - \(error.debugDescription)")
                return
            }
            
            if cursor != nil && !self.cancelRequest && (resultsLimit == nil || rowsRead < resultsLimit) {
                // More to come - recurse
                _ = self.download(recordType: recordType,
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
    
    public func backup(recordType: String, groupName: String, elementName: String, directory: [String], completion: @escaping (Bool, String)->()) {
        var records = 0
        var errorMessage = ""
        var ok = true
        
        
        if let fileHandle = openFile(directory: directory, recordType: recordType) {
            self.writeString(fileHandle: fileHandle, string: "{ \(groupName) : {\n")
            _ = self.download(recordType: recordType,
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
                                    errorMessage = "Error downloading table (\(message))"
            })
        } else {
            errorMessage = "Error creating backup file"
        }
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
}
