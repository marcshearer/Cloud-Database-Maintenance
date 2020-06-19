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
    private var playerUUID: [String : String] = [:]
    private var email: [String : String] = [:]
    private var step = 0

    public func execute(completion: @escaping (String)->()) {
        self.completion = completion
        
        self.controller()
    }
    
    private func controller(_ previousResult: String? = nil) {
        Utility.mainThread {
            if let result = previousResult {
                self.completion?(result)
            } else {
                self.step += 1
                switch self.step {
                case 1:
                    self.setupPlayerUUIDs(completion: self.controller)
                    
                case 2:
                    self.initialise(recordType: "Invites", completion: self.controller)
                    
                case 3:
                    self.initialise(recordType: "Notifications", completion: self.controller)
                    
                case 4:
                    self.initialise(recordType: "Links", completion: self.controller)
                    
                case 5:
                    self.replace(recordType: "Participants",
                                 keys: [("email", "playerUUID")],
                                 completion: self.controller)
                    
                case 6:
                    self.updateSettings(completion: self.controller)
                    
                default:
                    self.completion?("Success")
                }
            }
        }
    }
        
    private func setupPlayerUUIDs(completion: @escaping (String?)->()) {
        // Build cross refs for any existing player UUIDs and update players with any that are missing
        var updates: [CKRecord] = []
        var badPlayer = false
        
        self.iCloud.download(recordType: "players",
        downloadAction: { (record) in
            // Add to xref
            if let email = record.value(forKey: "email") as? String {
                var playerUUID = record.value(forKey: "playerUUID") as? String ?? ""
                if playerUUID == "" {
                    // Doesn't exist - allocate UUID and write it back
                    playerUUID = UUID().uuidString
                    record.setValue(playerUUID, forKey: "playerUUID")
                    updates.append(record)
                }
                // Add to cross ref
                self.playerUUID[email] = playerUUID
                self.email[playerUUID] = email
            } else {
                badPlayer = true
            }
        },
        completeAction: {
            if badPlayer {
                completion("Error reading player - invalid email or player UUID")
            } else {
                if !updates.isEmpty {
                    self.iCloud.update(records: updates) { (error) in
                        if error == nil {
                            completion(nil)
                        } else {
                            completion(self.iCloud.errorMessage(error))
                        }
                    }
                } else {
                    completion(nil)
                }
            }
        },
        failureAction: { (error) in
            completion("Error getting existing player UUIDs (\(self.iCloud.errorMessage(error)))")
        })
    }
    
    private func replace(recordType: String, keys: [(from: String, to: String)], completion: @escaping (String?)->()) {
        var updates: [CKRecord] = []
        
        self.iCloud.download(recordType: recordType,
        downloadAction: { (record) in
            var changed = false
            for key in keys {
                let fromValue = record.value(forKey: key.from) as! String
                let toValue = record.value(forKey: key.to) as? String ?? ""
                if fromValue == "" {
                    // From value is blank - to value should be either blank or a valid player UUID
                    if toValue != "" && self.email[toValue] == nil {
                        fatalError("Already converted but player UUID invalid")
                    }
                } else if key.from == key.to && self.email[fromValue] != nil {
                    // Replacing in situ and to value is already a valid player UUID
                } else {
                    // Should be an email which we can replace
                    if let playerUUID = self.playerUUID[fromValue] {
                        record.setValue(playerUUID, forKey: key.to)
                        if key.from != key.to {
                            record.setValue("", forKey: key.from)
                        }
                        changed = true
                    } else {
                        // Email found not in cross ref
                        fatalError("Invalid email detected")
                    }
                }
            }
            if changed {
                updates.append(record)
            }
        },
        completeAction: {
            if !updates.isEmpty {
                self.iCloud.update(records: updates) { (error) in
                    if error == nil {
                        completion(nil)
                    } else {
                        completion(self.iCloud.errorMessage(error))
                    }
                }
            } else {
                completion(nil)
            }
        },
        failureAction: { (error) in
            completion("Error replacing emails in \(recordType) (\(self.iCloud.errorMessage(error)))")
        })
    }
    
    private func initialise(recordType: String, completion: @escaping (String?)->()) {
        // Remove all records from this table
        self.iCloud.initialise(recordType: recordType, completion: { error in
            completion(error != nil ? self.iCloud.errorMessage(error) : nil)
        })
    }
    
    private func updateSettings(completion: @escaping (String?)->()) {
        var updates: [CKRecord] = []
        
        let cloudContainer = CKContainer.init(identifier: Config.iCloudIdentifier)
        let privateDatabase = cloudContainer.privateCloudDatabase
        
        self.iCloud.download(recordType: "Settings", database: privateDatabase,
        downloadAction: { (record) in
            let name = record.value(forKey: "name") as! String
            if name == "thisPlayerEmail" {
                let email = record.value(forKey: "value") as! String
                if email != "" {
                    if let playerUUID = self.playerUUID[email] {
                        record.setValue(playerUUID, forKey: "value")
                        updates.append(record)
                    } else {
                        fatalError("Invalid email detected")
                    }
                }
            }
        },
        completeAction: {
            if !updates.isEmpty {
                self.iCloud.update(records: updates) { (error) in
                    if error == nil {
                        completion(nil)
                    } else {
                        completion(self.iCloud.errorMessage(error))
                    }
                }
            } else {
                completion(nil)
            }
        },
        failureAction: { (error) in
            completion("Error updating settings (\(self.iCloud.errorMessage(error)))")
        })
    }
    
}
