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
        
        let recordTypes = ["Games",
                           "Invites",
                           "Links",
                           "Notifications",
                           "Participants",
                           "Players",
                           "Version"]
        
        func iterate(index: Int) {
            if index < recordTypes.count {
                let recordType = recordTypes[index]
                self.createReadableRecordIDs(recordType: recordType)
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
    
    func createReadableRecordIDs(recordType: String, completion: @escaping (Bool, String)->()) {
        var cloudObjectList: [CKRecord] = []
        var tempID: [String] = []
        
        self.iCloud.download(recordType: recordType,
        downloadAction: { (record) in
            cloudObjectList.append(record)
        },
        completeAction: {
            var recordIDsToDelete: [CKRecord.ID] = []
            var recordsToSave: [CKRecord] = []

            for cloudObject in cloudObjectList {
                
                let recordID = self.iCloud.recordID(from: cloudObject)
                if recordID.recordName != cloudObject.recordID.recordName {
                    let newCloudObject = CKRecord(recordType: recordType, recordID: recordID)
                    for key in cloudObject.allKeys() {
                        if key == "thumbnail" {
                            let thumbnail = Utility.objectImage(cloudObject: cloudObject, forKey: key)
                            if !Utility.imageToObject(cloudObject: newCloudObject, thumbnail: thumbnail, name: recordID.recordName) {
                                fatalError("Error copying image")
                            }
                            tempID.append(recordID.recordName)
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
