//
//  RestoreViewController.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 18/06/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Cocoa

class RestoreViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

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
            self.view.window?.title = "Retore Cloud Database (\(Utility.appDelegate!.database))"
            tableView.beginUpdates()
            self.results = []
            tableView.reloadData()
            tableView.endUpdates()
            self.firstTime = false
        }
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.prompt = "Select backup to restore"
        openPanel.level = .floating
        openPanel.begin { (result) in
            let directories = openPanel.urls
            let restore = Restore()
            restore.restore(directory: directories.first!,
            startTable: { (recordType) in
                              Utility.mainThread {
                                  self.tableView.beginUpdates()
                                  self.results.append((recordType, "Restoring \(recordType)..."))
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
                          })
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
