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
    private var tables: [(recordType: String, groupName: String, elementName: String, sortKey: [String]?, sortAscending: Bool?)] = []
    private var errors = false
    
    public func backup(resetMessage: Bool = false, disableMenu: Bool = false, startTable: ((String)->())? = nil, endTable: ((String, Bool, String)->())? = nil, completion: ((Bool, String)->())? = nil) {
        
        MenuBar.setBackupTitle(title: "Backup in progress...", enabled: (disableMenu ? false : nil))
        self.tables = []
        self.errors = false
        self.dateString = Utility.dateString(Date(), format: Config.backupDirectoryDateFormat, localized: false)
        
        self.addTable(recordType: "Players", groupName: "players", elementName:  "player", sortKey: ["name"], sortAscending: true)
        self.addTable(recordType: "Games", groupName: "games", elementName:  "game", sortKey: ["datePlayed"], sortAscending: false)
        self.addTable(recordType: "Participants", groupName: "participants", elementName:  "participant", sortKey: ["datePlayed", "totalScore"], sortAscending: false)
        self.addTable(recordType: "Invites", groupName: "invites", elementName:  "invite")
        self.addTable(recordType: "Notifications", groupName: "notifications", elementName:  "notification")
        self.addTable(recordType: "Version", groupName: "versions", elementName:  "version")
        if Utility.appDelegate!.database == "Development" {
               // TODO Remove condition once live
            self.addTable(recordType: "Links", groupName: "links", elementName: "link")
        }
         
        self.backupNext(count: 0,
                        resetMessage: resetMessage,
                        disableMenu: disableMenu,
                        startTable: startTable,
                        endTable: endTable,
                        completion: completion)
    }
    
    private func backupNext(count: Int, resetMessage: Bool, disableMenu: Bool = false, startTable: ((String)->())?, endTable: ((String, Bool, String)->())?, completion: ((Bool, String)->())?) {
        if count > self.tables.count - 1 {
            // Finished
            Utility.mainThread {
                if !self.errors {
                    MenuBar.setBackupDate(backupDate: Date())
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
        let fileManager = FileManager()
        
        let documentsUrl:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
        let backupsUrl = documentsUrl.appendingPathComponent("backups")
        let databaseBackupsUrl = backupsUrl.appendingPathComponent(Utility.appDelegate!.database)
        let thisBackupUrl = databaseBackupsUrl.appendingPathComponent(self.dateString)
        let assetsBackupUrl = databaseBackupsUrl.appendingPathComponent("assets")
        _ = (try? fileManager.createDirectory(at: thisBackupUrl, withIntermediateDirectories: true))
        _ = (try? fileManager.createDirectory(at: assetsBackupUrl, withIntermediateDirectories: true))
        
        self.iCloud.backup(recordType: recordType, groupName: groupName, elementName: elementName, sortKey: sortKey, sortAscending: sortAscending, directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, completion: completion)
    }
}

