//
//  EmailToUUID.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 13/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class EmailToUUID {
    
    public static let shared = EmailToUUID()
    private let iCloud = ICloud()
    private var completion: ((String)->())?
    
    public func execute(completion: @escaping (String)->()) {
        var players: [CKRecord] = []
        var existingPlayerUUID: [String : String] = [:]
        
        self.completion = completion
        
        self.iCloud.download(recordType: "playerUUIDs",
        downloadAction: { (record) in
            // Add to xref
            if let email = record.value(forKey: "email") as? String,
               let playerUUID = record.value(forKey: "playerUUID") as? String {
                existingPlayerUUID[email] = playerUUID
            }
        },
        completeAction: {
            self.iCloud.download(recordType: "Players",
            downloadAction: { (record) in
                players.append(record)
            },
            completeAction: {
                var cloudObjectList: [CKRecord] = []
                var recordIDsToDelete: [CKRecordID] = []
                
                for player in players {
                    if let email = player.value(forKey: "email") as? String {
                        let dateCreated = player.value(forKey: "dateCreated") as! Date
                        if Date().timeIntervalSince(dateCreated) <= 7*24*60*60 {
                            print(email)
                            recordIDsToDelete.append(player.recordID)
                        } else {
                            let playerUUID = existingPlayerUUID[email] ?? UUID().uuidString
                            let playerUUIDRecord = CKRecord(recordType: "PlayerUUIDs", recordID: CKRecord.ID(recordName: email))
                            playerUUIDRecord.setValue(email, forKey: "email")
                            playerUUIDRecord.setValue(playerUUID, forKey: "playerUUID")
                            playerUUIDRecord.setValue(Date(), forKey: "date")
                            cloudObjectList.append(playerUUIDRecord)
                            
                            // player.setValue(playerUUID, forKey: "email")
                            cloudObjectList.append(player)
                        }
                    }
                }
                
                if !players.isEmpty {
                    
                    let cloudContainer = CKContainer.init(identifier: Config.iCloudIdentifier)
                    let publicDatabase = cloudContainer.publicCloudDatabase
                    
                    let uploadOperation = CKModifyRecordsOperation(recordsToSave: cloudObjectList, recordIDsToDelete: recordIDsToDelete)
                    
                    uploadOperation.isAtomic = true
                    uploadOperation.database = publicDatabase
                    
                    uploadOperation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecords: [CKRecord.ID]?, error: Error?) -> Void in
                        if let error = error as? CKError {
                            if error.code != .partialFailure {
                                self.completion?("Error writing link records")
                            } else {
                                self.completion?("Success")
                            }
                        } else {
                            self.completion?("Success")
                        }
                    }
                    // Add the operation to an operation queue to execute it
                    OperationQueue().addOperation(uploadOperation)
                } else {
                    self.completion?("Success (nothing to do)")
                }
            },
            failureAction: { (error) in
                self.completion?("Error downloading players")
            })
        },
        failureAction: { (error) in
            self.completion?("Error downloading player UUIDs")
        })
    }
}
