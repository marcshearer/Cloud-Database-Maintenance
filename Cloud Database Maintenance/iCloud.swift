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
                                   downloadAction: ((CKRecord) -> ())?,
                                   completeAction: (() -> ())?,
                                   failureAction:  ((String) -> ())?,
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
        queryOperation.resultsLimit = (rowsRead < 100 ? 30 : 100)
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
            
            if cursor != nil && !self.cancelRequest {
                // More to come - recurse
                _ = self.download(recordType: recordType,
                                           keys: keys,
                                           sortKey: sortKey,
                                           sortAscending: sortAscending,
                                           predicate: predicate,
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
    
}
