//
//  CheckDuplicateParticipants.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 14/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//


import Foundation
import CloudKit

class CheckDuplicateParticipants {
    
    public static let shared = CheckDuplicateParticipants()
    private let iCloud = ICloud()
    private var completion: ((String)->())?
    
    public func execute(completion: @escaping (String)->()) {
        var recordIDs: [String] = []

        self.completion = completion
        
        iCloud.download(recordType: "Participants", downloadAction: { (record) in
            
            let date = record.value(forKey: "datePlayed") as! Date
            let datePlayed = Utility.dateString(date, format: "yyyy-MM-dd", localized: false)
            let email = record.value(forKey: "email")
            let gameUUID = record.value(forKey: "gameUUID")
            let recordID = "Games-\(datePlayed)-\(email!)-\(gameUUID!)"
            recordIDs.append(recordID)
        }, completeAction: {
            recordIDs.sort()
            var lastID: String?
            for recordID in recordIDs {
                if recordID == lastID {
                    completion("Duplicate participant \(recordID)")
                }
                lastID = recordID
            }
            completion("No duplicates")
        }, failureAction: { (error) in
            completion(error)
        })
    }
}
