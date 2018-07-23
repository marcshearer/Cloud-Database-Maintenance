//
//  BackupViewController.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 22/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa
import CloudKit
import Foundation

class BackupViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    private let iCloud = ICloud()
    private var dateString = ""
    private var tables: [(recordType: String, groupName: String, elementName: String)] = []
    private var results: [ (table: String, message: String) ] = []
    private var errors = false
    private var count = 0
    private var firstTime = true
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var closeButton: NSButton!
    
    @IBAction func closeButtonClick(_ sender: NSButton) {
        self.setBackupMenu(title: "Backup database")
        self.view.window?.close()
        self.firstTime = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if self.firstTime {
            self.tables = []
            self.errors = false
            self.count = 0
            tableView.beginUpdates()
            self.results = []
            tableView.reloadData()
            tableView.endUpdates()
            self.dateString = Utility.dateString(Date(), format: "yyyy-MM-dd-HH-mm-ss-SSS", localized: false)
            self.setBackupMenu(title: "Backup in progress")
            self.addTable(recordType: "Players", groupName: "players", elementName:  "player")
            self.addTable(recordType: "Games", groupName: "games", elementName:  "game")
            self.addTable(recordType: "Participants", groupName: "participants", elementName:  "participant")
            self.addTable(recordType: "Invites", groupName: "invites", elementName:  "invite")
            self.addTable(recordType: "Notifications", groupName: "notifications", elementName:  "notification")
            self.addTable(recordType: "Version", groupName: "versions", elementName:  "version")
            self.firstTime = false
            
            self.backupNext()
        }
    }
    
    internal func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }
    
    internal func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    internal func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }
    
    internal func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var value: String
        
        switch tableColumn?.identifier.rawValue {
        case "Table":
            value = results[row].table
        case "Message":
            value = results[row].message
        default:
            value = ""
        }
        return NSCell(textCell: value)
    }

    func backupNext() {
        if self.count > self.tables.count - 1 {
            Utility.mainThread {
                if !self.errors {
                    let backupDate = Utility.dateString(Date(), format: "EEEE dd MMMM YYYY HH:mm", localized: true)
                    UserDefaults.standard.set(backupDate, forKey: "backupDate")
                    Utility.appDelegate?.backupDateMenuItem.title = backupDate
                    self.setBackupMenu(title: "Backup complete\((self.errors ? " with errors" : ""))")
                }
                self.closeButton.isEnabled = true
            }
        } else {
            self.backupTable(recordType: self.tables[self.count].recordType, groupName: self.tables[self.count].groupName, elementName: self.tables[self.count].elementName)
            self.count += 1
        }
    }
    
    func addTable(recordType: String, groupName: String, elementName: String) {
        self.tables.append((recordType, groupName, elementName))
    }
    
    func backupTable(recordType: String, groupName: String, elementName: String) {
        var records = 0
        var errorMessage = ""
        var ok = false
        var recordsWrittenOk = true
       
        Utility.mainThread {
            self.tableView.beginUpdates()
            self.results.append((recordType, "Backing up \(recordType)..."))
            self.tableView.insertRows(at: IndexSet(integer: self.results.count - 1), withAnimation: .slideUp)
            self.tableView.endUpdates()
        }
        
        if let fileHandle = openFile(recordType: recordType) {
            self.writeString(fileHandle: fileHandle, string: "{ \(groupName) : {\n")
            _ = self.iCloud.download(recordType: recordType,
                                     downloadAction: { (record) in
                                        records += 1
                                        if records > 1 {
                                            self.writeString(fileHandle: fileHandle, string: ",\n")
                                        }
                                        self.writeString(fileHandle: fileHandle, string: "     \(elementName) : ")
                                        if !self.writeRecord(fileHandle: fileHandle, elementName: elementName, record: record) {
                                            errorMessage = "Error writing record"
                                            recordsWrittenOk = false
                                        }
            },
                                     completeAction: {
                                        self.writeString(fileHandle: fileHandle, string: "\n     }")
                                        self.writeString(fileHandle: fileHandle, string: "\n}")
                                        fileHandle.closeFile()
                                        ok = recordsWrittenOk
                                        self.errors = self.errors || !ok
                                        Utility.mainThread {
                                            self.tableView.beginUpdates()
                                            self.results[self.results.count - 1].message = (ok ? "Successfully backed up \(records) \(recordType)" : ( errorMessage != "" ? errorMessage : "Unexpected error"))
                                            self.tableView.reloadData(forRowIndexes: IndexSet(integer: self.results.count - 1), columnIndexes: IndexSet(integer: 1))
                                            self.tableView.endUpdates()
                                        }   
                                        self.backupNext()                                        
            },
                                     failureAction: { (message) in
                                        fileHandle.closeFile()
                                        errorMessage = "Error downloading table (\(message))"
            })
        } else {
            errorMessage = "Error creating backup file"
        }
    }
    
    private func openFile(recordType: String) -> FileHandle! {
        var fileHandle: FileHandle!
        
        let dirUrl:NSURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as NSURL
        if let subDirUrl = dirUrl.appendingPathComponent("backups") {
            let dateDirUrl = subDirUrl.appendingPathComponent(self.dateString)
            let fileUrl =  dateDirUrl.appendingPathComponent("\(recordType).json")
            let fileManager = FileManager()
            do {
                try fileManager.createDirectory(at: dateDirUrl, withIntermediateDirectories: true)
            } catch {
            }
            fileManager.createFile(atPath: fileUrl.path, contents: nil)
            fileHandle = FileHandle(forWritingAtPath: fileUrl.path)
        }
            
        return fileHandle
    }
    
    private func writeRecord(fileHandle: FileHandle, elementName: String, record: CKRecord) -> Bool {
        // Build a dictionary from the record
        var dictionary: [String : String] = [:]
        
        for key in record.allKeys() {
            let value = Utility.objectAsString(cloudObject: record, forKey: key)
            dictionary[key] = value
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            // error
            return false
        }
        fileHandle.write(data)
        return true
    }

    private func writeString(fileHandle: FileHandle, string: String) {
        let data = string.data(using: .utf8)!
        fileHandle.write(data)
    }
    
    private func setBackupMenu(title: String) {
        Utility.appDelegate?.backupMenuItem.title = title
    }
}
