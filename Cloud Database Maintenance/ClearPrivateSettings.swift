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
    
    public func execute(completion: @escaping (String)->()) {
        
        let cloudContainer = CKContainer.init(identifier: Config.iCloudIdentifier)
        let privateDatabase = cloudContainer.privateCloudDatabase
        
        self.iCloud.initialise(recordType: "Settings", database: privateDatabase) { (error) in
            completion(self.iCloud.errorMessage(error))
        }
    }
}
