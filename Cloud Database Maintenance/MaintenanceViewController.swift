//
//  MaintenanceViewController.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 12/06/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa
import CloudKit

enum VarType {
    case string
    case date
    case int
    case double
    case bool
}

struct Layout {
    var key: String
    var title: String
    var width: CGFloat
    var alignment: NSTextAlignment
    var type: VarType
    var total: Bool
}

class MaintenanceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, TableViewerDelegate {
    
    private var playersLayout: [Layout]!
    private var gamesLayout: [Layout]!
    private var participantsLayout: [Layout]!
    private var tableViewer: TableViewer!
    private var firstTime = true

    @IBOutlet weak var tableList: NSTableView!
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableList.delegate = self
        self.tableList.dataSource = self
        self.setupTableList()
        self.setupLayouts()
        
        self.tableViewer = TableViewer(displayTableView: self.tableView)
        self.tableViewer.delegate = self
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func setupTableList() {
        // Remove any existing columns
        let tableColumn = NSTableColumn()
        let headerCell = NSTableHeaderCell()
        headerCell.title = "Tables"
        tableColumn.headerCell = headerCell
        tableColumn.width = 200
        self.tableList.addTableColumn(tableColumn)
    }
    
    internal func status(isBusy: Bool) {
    }
    
    internal func shouldSelect(recordType: String, record: CKRecord) -> Bool {
        var result = false
        
        switch recordType {
        case "Players":
            if let email = Utility.objectString(cloudObject: record, forKey: "email") {
                let predicate = NSPredicate(format: "email = %@", email)
                self.tableViewer.show(recordType: "Participants", layout: self.participantsLayout, sortAscending: false, predicate: predicate)
                self.tableList.deselectAll(self)
                result = true
            }
        case "Games":
            if let gameUUID = Utility.objectString(cloudObject: record, forKey: "gameUUID") {
                let predicate = NSPredicate(format: "gameUUID = %@", gameUUID)
                self.tableViewer.show(recordType: "Participants", layout: self.participantsLayout, sortAscending: true, predicate: predicate)
                self.tableList.deselectAll(self)
                result = true
            }
        case "Participants":
            if let email = Utility.objectString(cloudObject: record, forKey: "email") {
                let predicate = NSPredicate(format: "email = %@", email)
                self.tableViewer.show(recordType: "Players", layout: self.playersLayout, sortAscending: true, predicate: predicate)
                self.tableList.deselectAll(self)
                result = true
            }
        default:
            break
        }
        
        return result
        
    }
    
    internal func numberOfRows(in tableView: NSTableView) -> Int {
        return 3
    }
    
    internal func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        switch row {
        case 0:
            self.tableViewer.show(recordType: "Players", layout: self.playersLayout, sortAscending: true)
        case 1:
            self.tableViewer.show(recordType: "Games", layout: self.gamesLayout, sortAscending: false)
        case 2:
            self.tableViewer.show(recordType: "Participants", layout: self.participantsLayout, sortAscending: false)
        default:
            break
        }
        
        return true
        
    }
    
    internal func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }
    
    internal func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var cell: NSCell!
        var table: String
        
        switch row {
        case 0:
            table = "Players"
            if firstTime {
                self.tableViewer.show(recordType: "Players", layout: self.playersLayout, sortAscending: true)
                tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                firstTime = false
            }
        case 1:
            table = "Games"
        case 2:
            table = "Participants"
        default:
            table = ""
        }
        
        cell = NSCell(textCell: table)
        
        return cell
    }
        private func setupLayouts() {
        
        playersLayout =
            [ Layout(key: "name",         title: "Name",          width: 80,      alignment: .left,   type: .string, total: false),
            Layout(key: "nameDate",     title: "Name date",     width: 80,      alignment: .center, type: .date, total: false),
            Layout(key: "dateCreated",  title: "Date Created",  width: 75,      alignment: .center, type: .date, total: false),
            Layout(key: "datePlayed",   title: "Last played",   width: 75,      alignment: .center, type: .date, total: false),
            Layout(key: "email",        title: "Email",         width: -150,    alignment: .left,   type: .string, total: false),
            Layout(key: "emailDate",    title: "Email date",    width: 80,      alignment: .center, type: .date, total: false),
            Layout(key: "externalId",   title: "External ID",   width: -80,     alignment: .left,   type: .string, total: false),
            Layout(key: "totalScore",   title: "Total" ,        width: 50,      alignment: .right,  type: .int, total: true),
            Layout(key: "gamesPlayed",  title: "Played",        width: 50,      alignment: .right,  type: .int, total: true),
            Layout(key: "gamesWon",     title: "Won",           width: 50,      alignment: .right,  type: .int, total: true),
            Layout(key: "handsPlayed",  title: "Hands",         width: 50,      alignment: .right,  type: .int, total: true),
            Layout(key: "handsMade",    title: "Made",          width: 50,      alignment: .right,  type: .int, total: true),
            Layout(key: "twosMade",     title: "Twos",          width: 50,      alignment: .right,  type: .int, total: true),
            Layout(key: "maxScore",     title: "^Score",        width: 50,      alignment: .right,  type: .int, total: false),
            Layout(key: "maxScoreDate", title: "Date",          width: 75,      alignment: .center, type: .date, total: false),
            Layout(key: "maxMade",      title: "^Made",         width: 50,      alignment: .right,  type: .int, total: false),
            Layout(key: "maxMadeDate",  title: "Date",          width: 75,      alignment: .center, type: .date, total: false),
            Layout(key: "maxTwos",      title: "^Twos",         width: 50,      alignment: .right,  type: .int, total: false),
            Layout(key: "maxTwosDate",  title: "Date",          width: 75,      alignment: .center, type: .date, total: false),
            Layout(key: "syncDate",     title: "Sync date",     width: 75,      alignment: .center, type: .date, total: false),
            Layout(key: "thumbnailDate",title: "Thumbnail",     width: 75,      alignment: .center, type: .date, total: false)     ]
        
        gamesLayout =
            [ Layout(key: "datePlayed",   title: "Last played",   width: 75,      alignment: .center, type: .date, total: false),
              Layout(key: "deviceName",   title: "Device",        width: -100,    alignment: .left,   type: .string, total: false),
              Layout(key: "location",     title: "Location",      width: -100,    alignment: .left,   type: .string, total: false),
              Layout(key: "latitude",     title: "Lat",           width: 50,      alignment: .left,   type: .double, total: false),
              Layout(key: "longitude",    title: "Long",          width: 50,      alignment: .left,   type: .double, total: false),
              Layout(key: "excludeStats", title: "Excl",          width: 30,      alignment: .center, type: .bool, total: false),
              Layout(key: "syncDate",     title: "Sync date",     width: 75,      alignment: .center, type: .date, total: false),
              Layout(key: "gameUUID",     title: "Game ID",       width: -150,    alignment: .left,   type: .string, total: false),
              Layout(key: "deviceUUID",   title: "Device ID",     width: -150,    alignment: .left,   type: .string, total: false) ]

        participantsLayout =
            [ Layout(key: "datePlayed",   title: "Last played",   width: 75,      alignment: .center, type: .date, total: false),
              Layout(key: "name",         title: "Name",          width: 80,      alignment: .left,   type: .string, total: false),
              Layout(key: "email",        title: "Email",         width: -150,    alignment: .left,   type: .string, total: false),
              Layout(key: "totalScore",   title: "Score" ,        width: 50,      alignment: .right,  type: .int, total: true),
              Layout(key: "gamesPlayed",  title: "Played",        width: 50,      alignment: .right,  type: .int, total: true),
              Layout(key: "gamesWon",     title: "Won",           width: 50,      alignment: .right,  type: .int, total: true),
              Layout(key: "handsPlayed",  title: "Hands",         width: 50,      alignment: .right,  type: .int, total: true),
              Layout(key: "handsMade",    title: "Made",          width: 50,      alignment: .right,  type: .int, total: true),
              Layout(key: "twosMade",     title: "Twos",          width: 50,      alignment: .right,  type: .int, total: true),
              Layout(key: "place",        title: "Position",      width: 50,      alignment: .right,  type: .int, total: false),
              Layout(key: "playerNumber", title: "Player",        width: 50,      alignment: .right,  type: .int, total: false),
              Layout(key: "excludeStats", title: "Excl",          width: 30,      alignment: .center, type: .bool, total: false),
              Layout(key: "syncDate",     title: "Sync date",     width: 75,      alignment: .center, type: .date, total: false),
              Layout(key: "gameUUID",     title: "Game ID",       width: -150,    alignment: .left,   type: .string, total: false),
              Layout(key: "deviceUUID",   title: "Device ID",     width: -150,    alignment: .left,   type: .string, total: false) ]

    }
    
}
