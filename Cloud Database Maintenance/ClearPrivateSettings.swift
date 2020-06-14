//
//  ClearPrivateSettings.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 13/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class ClearPrivateSettings {
    
    public static let shared = ClearPrivateSettings()
    private let iCloud = ICloud()
    private var completion: ((String)->())?
    
    public func execute(completion: @escaping (String)->()) {
        var recordIDsToDelete: [CKRecordID] = []
        
        self.completion = completion
        
        let cloudContainer = CKContainer.init(identifier: Config.iCloudIdentifier)
        let privateDatabase = cloudContainer.privateCloudDatabase
        
        self.iCloud.download(recordType: "Settings", database: privateDatabase, downloadAction: { (record) in
            recordIDsToDelete.append(record.recordID)
        },
        completeAction: {
            self.iCloud.update(records: nil, recordIDsToDelete: recordIDsToDelete) { (error) in
                completion(self.iCloud.errorMessage(error))
            }
        },
        failureAction: { (error) in
            self.completion?("Error downloading participants")
        })
    }
}
