//
//  BackupViewController.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 22/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa

class BackupViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    private var results: [ (table: String, message: String) ] = []
    private var firstTime = true
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var closeButton: NSButton!
    
    @IBAction func closeButtonClick(_ sender: NSButton) {
        MenuBar.setBackupTitle(title: "Backup database")
        self.view.window?.close()
        self.firstTime = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if self.firstTime {
            tableView.beginUpdates()
            self.results = []
            tableView.reloadData()
            tableView.endUpdates()
            self.firstTime = false
            
            let backup = Backup()
            
            backup.backup(startTable: { (recordType) in
                                            Utility.mainThread {
                                                self.tableView.beginUpdates()
                                                self.results.append((recordType, "Backing up \(recordType)..."))
                                                self.tableView.insertRows(at: IndexSet(integer: self.results.count - 1), withAnimation: .slideUp)
                                                self.tableView.endUpdates()
                                            }
                                        },
                          endTable: { (recordType, ok, message) in
                                            Utility.mainThread {
                                                self.tableView.beginUpdates()
                                                self.results[self.results.count - 1].message = message
                                                self.tableView.reloadData(forRowIndexes: IndexSet(integer: self.results.count - 1), columnIndexes: IndexSet(integer: 1))
                                                self.tableView.endUpdates()
                                            }
                                        },
                          completion: { (ok, message) in
                                            if !ok {
                                                Utility.alertMessage(message)
                                            }
                                            self.closeButton.isEnabled = true
                                        }
            )
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
}
