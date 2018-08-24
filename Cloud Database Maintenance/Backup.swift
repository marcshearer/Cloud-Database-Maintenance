//
//  Backup.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 28/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Foundation

class Backup {
    
    private let iCloud = ICloud()
    private var dateString = ""
    private var database = "unknown"
    private var tables: [(recordType: String, groupName: String, elementName: String, sortKey: [String]?, sortAscending: Bool?)] = []
    private var errors = false
    
    public func backup(resetMessage: Bool = false, disableMenu: Bool = false, startTable: ((String)->())? = nil, endTable: ((String, Bool, String)->())? = nil, completion: ((Bool, String)->())? = nil) {
        
        MenuBar.setBackupTitle(title: "Backup in progress...", enabled: (disableMenu ? false : nil))
        self.tables = []
        self.errors = false
        self.dateString = Utility.dateString(Date(), format: "yyyy-MM-dd-HH-mm-ss-SSS", localized: false)
        
        self.addTable(recordType: "Players", groupName: "players", elementName:  "player", sortKey: ["name"], sortAscending: true)
        self.addTable(recordType: "Games", groupName: "games", elementName:  "game", sortKey: ["datePlayed"], sortAscending: false)
        self.addTable(recordType: "Participants", groupName: "participants", elementName:  "participant", sortKey: ["datePlayed", "totalScore"], sortAscending: false)
        self.addTable(recordType: "Invites", groupName: "invites", elementName:  "invite")
        self.addTable(recordType: "Notifications", groupName: "notifications", elementName:  "notification")
        self.addTable(recordType: "Version", groupName: "versions", elementName:  "version")
        
        iCloud.getDatabaseIdentifier { (success, errorMessage, database) in
        
            if !success {
                MenuBar.setBackupTitle(title: "Backup failed (Database)", enabled: true)
                
            } else {
                
                self.database = database!
                
                self.backupNext(count: 0,
                            resetMessage: resetMessage,
                            disableMenu: disableMenu,
                            startTable: startTable,
                            endTable: endTable,
                            completion: completion)
            }
        }
    }
    
    private func backupNext(count: Int, resetMessage: Bool, disableMenu: Bool = false, startTable: ((String)->())?, endTable: ((String, Bool, String)->())?, completion: ((Bool, String)->())?) {
        if count > self.tables.count - 1 {
            // Finished
            Utility.mainThread {
                if !self.errors {
                    MenuBar.setBackupDate(backupDate: Date(), database: self.database)
                }
                let message = "Backup complete\((self.errors ? " with errors" : ""))"
                MenuBar.setBackupTitle(title: (resetMessage ? "Backup Database" : message),
                                       enabled: (disableMenu ? true : nil))
                completion?(!self.errors, message)
            }
        } else {
            startTable?(self.tables[count].recordType)
            self.backupTable(recordType: self.tables[count].recordType,
                             groupName: self.tables[count].groupName,
                             elementName: self.tables[count].elementName,
                             sortKey: self.tables[count].sortKey,
                             sortAscending: self.tables[count].sortAscending,
                             completion: { (ok, message) in
                                self.errors = self.errors || !ok
                                endTable?(self.tables[count].recordType, ok, message)
                                self.backupNext(count: count+1,
                                                resetMessage: resetMessage,
                                                disableMenu: disableMenu,
                                                startTable: startTable,
                                                endTable: endTable,
                                                completion: completion)
            })
        }
    }
    
    private func addTable(recordType: String, groupName: String, elementName: String, sortKey: [String]? = nil, sortAscending: Bool? = nil) {
        self.tables.append((recordType, groupName, elementName, sortKey, sortAscending))
    }
    
    private func backupTable(recordType: String, groupName: String, elementName: String, sortKey: [String]? = nil, sortAscending: Bool? = nil, completion: @escaping (Bool, String)->()) {
        
        self.iCloud.backup(recordType: recordType, groupName: groupName, elementName: elementName, sortKey: sortKey, sortAscending: sortAscending, directory: ["backups", database, dateString], completion: completion)
    }
}

