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
    private var links: [(fromPlayer: String, toPlayer: String)] = []
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
                participants.append((player: player, gameUUID: gameUUID))
            }
        },
        completeAction: {
            var cloudObjectList: [CKRecord] = []
            
            if !participants.isEmpty {
                participants.sort(by: {$0.gameUUID < $1.gameUUID})
                var lastGameUUID: String?
                var gamePlayers: [String] = []
                for participant in participants {
                    if participant.gameUUID != lastGameUUID {
                        if lastGameUUID != nil {
                            self.addLinks(gamePlayers)
                        }
                        gamePlayers = []
                        lastGameUUID = participant.gameUUID
                    }
                    gamePlayers.append(participant.player)
                }
                if !gamePlayers.isEmpty {
                    self.addLinks(gamePlayers)
                }
            }
            
            for link in self.links {
                let cloudObject = CKRecord(recordType: "Links", recordID:  CKRecord.ID(recordName: "Links-\(link.fromPlayer)-\(link.toPlayer)"))
                cloudObject.setValue(link.fromPlayer, forKey: "fromPlayer")
                cloudObject.setValue(link.toPlayer, forKey: "toPlayer")
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
    
    private func addLinks(_ gamePlayers: [String]) {
        for fromPlayer in gamePlayers {
            if let fromEmail = emails[fromPlayer] {
                for toPlayer in gamePlayers {
                    if fromPlayer != toPlayer {
                        if links.first(where: { $0.fromPlayer == fromEmail && $0.toPlayer == toPlayer }) == nil {
                            links.append((fromPlayer: fromEmail, toPlayer: toPlayer))
                        }
                    }
                }
            } else {
                fatalError("Invalid player UUID encountered")
            }
        }
    }
}
