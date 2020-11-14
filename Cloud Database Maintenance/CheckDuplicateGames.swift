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
          recordIDs.append(self.iCloud.recordID(from: record).recordName)
        }, completeAction: {
            recordIDs.sort()
            var lastID: String?
            for recordID in recordIDs {
                if recordID == lastID {
                    completion("Duplicate game \(recordID)")
                }
                lastID = recordID
            }
            completion("No duplicates")
        }, failureAction: { (error) in
            completion("Error downloading games (\(self.iCloud.errorMessage(error)))")
        })
    }
}
