//
//  CheckDuplicateGames.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 14/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class CheckDuplicateGames {
    
    public static let shared = CheckDuplicateGames()
    private let iCloud = ICloud()
    private var completion: ((String)->())?
    
    public func execute(completion: @escaping (String)->()) {
        var recordIDs: [String] = []

        self.completion = completion
        
        iCloud.download(recordType: "Games", downloadAction: { (record) in
            
            let date = record.value(forKey: "datePlayed") as! Date
            let datePlayed = Utility.dateString(date, format: "yyyy-MM-dd", localized: false)
            let deviceName = record.value(forKey: "deviceName")
            let gameUUID = record.value(forKey: "gameUUID")
            let recordID = "Games-\(datePlayed)-\(deviceName!)-\(gameUUID!)"
            recordIDs.append(recordID)
        }, completeAction: {
            recordIDs.sort()
            var lastID: String?
            for recordID in recordIDs {
                if recordID == lastID {
                    completion("Duplicate game \(recordID)")
                }
                lastID = recordID
            }
            completion("Success")
        }, failureAction: { (error) in
            completion(error)
        })
    }
}
