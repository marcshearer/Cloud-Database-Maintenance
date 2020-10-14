//
//  Restore.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 18/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation

class Restore {
    
    private let iCloud = ICloud()
    private var dateString = ""
    private var tables: [(recordType: String, groupName: String, elementName: String)] = []
    private var errors = false
    
    public func restore(directory: URL, startTable: ((String)->())? = nil, endTable: ((String, Bool, String)->())? = nil, completion: ((Bool, String)->())? = nil) {
        
        MenuBar.setRestoreTitle(title: "Restore in progress...", enabled: false)
        self.tables = []
        self.errors = false
        
        self.addTable(recordType: "Players", groupName: "players", elementName:  "player")
        self.addTable(recordType: "Games", groupName: "games", elementName:  "game")
        self.addTable(recordType: "Participants", groupName: "participants", elementName:  "participant")
        self.addTable(recordType: "Invites", groupName: "invites", elementName:  "invite")
        self.addTable(recordType: "Notifications", groupName: "notifications", elementName:  "notification")
        self.addTable(recordType: "Version", groupName: "versions", elementName:  "version")
        self.addTable(recordType: "Links", groupName: "links", elementName: "link")
        self.addTable(recordType: "Awards", groupName: "awards", elementName: "award")
        self.addTable(recordType: "Terms", groupName: "terms", elementName: "terms")
        
        self.restoreNext(count: 0,
                         directory: directory,
                         startTable: startTable,
                         endTable: endTable,
                         completion: completion)
    }
    
    private func restoreNext(count: Int, directory: URL, startTable: ((String)->())?, endTable: ((String, Bool, String)->())?, completion: ((Bool, String)->())?) {
        if count > self.tables.count - 1 {
            // Finished
            Utility.mainThread {
                if !self.errors {
                    MenuBar.setBackupDate(backupDate: Date())
                }
                let message = "Restore complete\((self.errors ? " with errors" : ""))"
                    MenuBar.setRestoreTitle(title: "Restore Database",
                                            enabled: true)
                completion?(!self.errors, message)
            }
        } else {
            startTable?(self.tables[count].recordType)
            self.restoreTable(directory: directory,
                             recordType: self.tables[count].recordType,
                             groupName: self.tables[count].groupName,
                             elementName: self.tables[count].elementName,
                             completion: { (ok, message) in
                                self.errors = self.errors || !ok
                                endTable?(self.tables[count].recordType, ok, message)
                                self.restoreNext(count: count + 1,
                                                 directory: directory,
                                                 startTable: startTable,
                                                 endTable: endTable,
                                                 completion: completion)
            })
        }
    }
    
    private func addTable(recordType: String, groupName: String, elementName: String) {
        self.tables.append((recordType, groupName, elementName))
    }
    
    private func restoreTable(directory: URL, recordType: String, groupName: String, elementName: String, completion: @escaping (Bool, String)->()) {
        
        let baseDirectory = directory.deletingLastPathComponent()
        let assetsDirectory = baseDirectory.appendingPathComponent("assets")
        
        self.iCloud.restore(directory: directory, assetsDirectory: assetsDirectory, recordType: recordType, groupName: groupName, elementName: elementName, completion: completion)
    }
}

