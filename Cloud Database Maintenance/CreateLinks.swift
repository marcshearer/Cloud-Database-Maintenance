//
//  CreateLinks.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 03/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class CreateLinks {
    
    public static let shared = CreateLinks()
    private let iCloud = ICloud()
    private var links: [(fromEmail: String, fromPlayerUUID: String, toPlayerUUID: String)] = []
    private var emails: [String:String] = [:]
    
    public func execute(completion: @escaping (String)->()) {
        self.iCloud.getPlayerUUIDs(completion: { (emails) in
            if emails == nil {
                completion("Error loading email/player UUID cross-ref")
            } else {
                self.emails = emails!
                self.iCloud.initialise(recordType: "links") { (error) in
                    if error != nil {
                        completion("Error clearing links table")
                    } else {
                        self.createLinks(completion: completion)
                    }
                }
            }
        })
    }
    
    private func createLinks(completion: @escaping (String)->()) {
        var participants: [(gameUUID: String, player: String)] = []
        
        self.iCloud.download(recordType: "Participants", downloadAction: { (record) in
            if let player = record.value(forKey: "playerUUID") as? String,
                let gameUUID = record.value(forKey: "gameUUID") as? String {
                participants.append((gameUUID: gameUUID, player: player))
            }
        },
        completeAction: {
            var cloudObjectList: [CKRecord] = []
            
            if !participants.isEmpty {
                participants.sort(by: {$0.gameUUID < $1.gameUUID})
                var lastGameUUID: String?
                var gamePlayerUUIDs: [String] = []
                for participant in participants {
                    if participant.gameUUID != lastGameUUID {
                        if lastGameUUID != nil {
                            self.addLinks(gamePlayerUUIDs)
                        }
                        gamePlayerUUIDs = []
                        lastGameUUID = participant.gameUUID
                    }
                    gamePlayerUUIDs.append(participant.player)
                }
                if !gamePlayerUUIDs.isEmpty {
                    self.addLinks(gamePlayerUUIDs)
                }
            }
            
            for link in self.links {
                let cloudObject = CKRecord(recordType: "Links", recordID:  CKRecord.ID(recordName: "Links-\(link.fromEmail)-\(link.toPlayerUUID)"))
                cloudObject.setValue(link.fromEmail, forKey: "fromEmail")
                cloudObject.setValue(link.fromPlayerUUID, forKey: "fromPlayerUUID")
                cloudObject.setValue(link.toPlayerUUID, forKey: "toPlayerUUID")
                cloudObjectList.append(cloudObject)
            }
            
            if !cloudObjectList.isEmpty {
                self.iCloud.update(records: cloudObjectList, recordIDsToDelete: nil) { (error) in
                    completion(self.iCloud.errorMessage(error))
                }
            } else {
                completion("Success (nothing to do)")
            }
        },
        failureAction: { (error) in
            completion("Error downloading participants")
        })
    }
    
    private func addLinks(_ gamePlayerUUIDs: [String]) {
        for fromPlayerUUID in gamePlayerUUIDs {
            if let fromEmail = emails[fromPlayerUUID] {
                for toPlayerUUID in gamePlayerUUIDs {
                    // Note these even creates a link for each player with themselves
                    if links.first(where: { $0.fromEmail == fromEmail && $0.toPlayerUUID == toPlayerUUID }) == nil {
                        links.append((fromEmail: fromEmail, fromPlayerUUID: fromPlayerUUID, toPlayerUUID: toPlayerUUID))
                    }
                }
            } else {
                fatalError("Invalid player UUID encountered")
            }
        }
    }
}
