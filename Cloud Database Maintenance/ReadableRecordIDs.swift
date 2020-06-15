//
//  ReadableRecordIDs.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 13/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class ReadableRecordIDs {
    
    public static let shared = ReadableRecordIDs()
    private let iCloud = ICloud()
    private var completion: ((String)->())?
    
    public func execute(completion: @escaping (String)->()) {
        
        self.completion = completion
        
        let actions = [(recordType: "Games", columns: ["datePlayed", "deviceName", "gameUUID"]),
                       (recordType: "Invites", columns: ["hostName", "hostPlayerUUID", "invitePlayerUUID", "inviteUUID"]),
                       (recordType: "Links", columns: ["fromPlayer", "toPlayer"]),
                       (recordType: "Notifications", columns: ["playerUUID"]),
                       (recordType: "Participants", columns: ["datePlayed", "playerUUID", "gameUUID"]),
                       (recordType: "Players", columns: ["name", "email"]),
                       (recordType: "Version", columns: [])]
        
        func iterate(index: Int) {
            if index < actions.count {
                let action = actions[index]
                self.createReadableRecordIDs(recordType: action.recordType, columns: action.columns)
                { (success, message) in
                    if success {
                        iterate(index: index + 1)
                    } else {
                        self.completion?(message)
                    }
                }
            } else {
                self.completion?("Success")
            }
        }
        
        iterate(index: 0)
    }
    
    func createReadableRecordIDs(recordType: String, columns: [String], completion: @escaping (Bool, String)->()) {
        var cloudObjectList: [CKRecord] = []
        var tempID: [String] = []
        
        self.iCloud.download(recordType: recordType,
        downloadAction: { (record) in
            cloudObjectList.append(record)
        },
        completeAction: {
            var recordIDsToDelete: [CKRecordID] = []
            var recordsToSave: [CKRecord] = []

            for cloudObject in cloudObjectList {
                
                var recordID = recordType
                for column in columns {
                    recordID += "-"
                    let value = cloudObject.value(forKey: column)
                    if let date = value as? Date {
                        recordID += Utility.dateString(date, format: "yyyy-MM-dd", localized: false)
                    } else if value == nil {
                        recordID += "NULL"
                    } else {
                        recordID += value as! String
                    }
                }
                if recordID != cloudObject.recordID.recordName {
                    let newCloudObject = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: recordID))
                    for key in cloudObject.allKeys() {
                        if key == "thumbnail" {
                            let thumbnail = Utility.objectImage(cloudObject: cloudObject, forKey: key)
                            if !Utility.imageToObject(cloudObject: newCloudObject, thumbnail: thumbnail, name: recordID) {
                                fatalError("Error copying image")
                            }
                            tempID.append(recordID)
                        } else {
                            let value = cloudObject.value(forKey: key)
                            newCloudObject.setValue(value, forKey: key)
                        }
                    }
                    recordsToSave.append(newCloudObject)
                    recordIDsToDelete.append(cloudObject.recordID)
                }
            }
            
            
            if !recordsToSave.isEmpty || !recordIDsToDelete.isEmpty {
                self.iCloud.update(records: recordsToSave, recordIDsToDelete: recordIDsToDelete) { (error) in
                    for id in tempID {
                        Utility.tidyObject(name: id)
                    }
                    completion(error == nil, self.iCloud.errorMessage(error))
                }
            } else {
                completion(true, "Success (nothing to do)")
            }
        },
        failureAction: { (error) in
            completion(false, "Error downloading \(recordType)")
        })
    }
}
