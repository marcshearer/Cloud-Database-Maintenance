//
//  MaintenanceViewController.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 12/06/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa
import CloudKit

class MaintenanceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, CloudTableViewerDelegate {
    
    private var playersLayout: [Layout]!
    private var gamesLayout: [Layout]!
    private var participantsLayout: [Layout]!
    private var invitesLayout: [Layout]!
    private var notificationsLayout: [Layout]!
    private var versionLayout: [Layout]!
    private var linksLayout: [Layout]!
    private var awardsLayout: [Layout]!
    private var termsLayout: [Layout]!
    private var tableViewer: CloudTableViewer!
    private var firstTime = true
    private var emails: [String:String] = [:]
    private var iCloud = ICloud()

    @IBOutlet weak var tableList: NSTableView!
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableList.delegate = self
        self.tableList.dataSource = self
        self.setupTableList()
        self.setupLayouts()
        
        self.tableViewer = CloudTableViewer(displayTableView: self.tableView)
        self.tableViewer.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "Cloud Database Maintenance (\(Utility.appDelegate!.database))"
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
    
    internal func derivedKey(recordType: String, key: String, record: CKRecord) -> String {
        return ""
    }
    
    internal func emailSubstitute(recordType: String, key: String, record: CKRecord) -> String {
        var result: String?
        
        if let value = record.value(forKey: key) as? String {
            result = self.emails[value] ?? value
        }
        
        return result ?? ""
    }
    
    internal func numberOfRows(in tableView: NSTableView) -> Int {
        return 9
    }
    
    internal func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        switch row {
        case 0:
            self.tableViewer.show(recordType: "Players",
                                  layout: self.playersLayout,
                                  sortAscending: true)
        case 1:
            self.tableViewer.show(recordType: "Games",
                                  layout: self.gamesLayout,
                                  sortAscending: false)
        case 2:
            self.tableViewer.show(recordType: "Participants",
                                  layout: self.participantsLayout,
                                  sortAscending: false)
        case 3:
            self.tableViewer.show(recordType: "Invites",
                                  layout: self.invitesLayout,
                                  sortAscending: false)
        case 4:
            self.tableViewer.show(recordType: "Notifications",
                                  layout: self.notificationsLayout,
                                  sortKey: "playerUUID",
                                  sortAscending: false)
        case 5:
            self.tableViewer.show(recordType: "Version",
                                  layout: self.versionLayout,
                                  sortAscending: false)
        case 6:
            self.tableViewer.show(recordType: "Links",
                                  layout: self.linksLayout,
                                  sortAscending: false)
        case 7:
            self.tableViewer.show(recordType: "Awards",
                                  layout: self.awardsLayout,
                                  sortAscending: true)
            
        case 8:
            self.tableViewer.show(recordType: "Terms",
                                  layout: self.termsLayout,
                                  sortKey: "userId",
                                  sortAscending: true)
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
                self.iCloud.getPlayerUUIDs() { (emails) in
                    Utility.mainThread {
                        self.emails = emails ?? [:]
                        self.tableViewer.show(recordType: "Players", layout: self.playersLayout, sortAscending: true)
                        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                        self.firstTime = false
                    }
                }
            }
        case 1:
            table = "Games"
        case 2:
            table = "Participants"
        case 3:
            table = "Invites"
        case 4:
            table = "Notifications"
        case 5:
            table = "Version"
        case 6:
            table = "Links"
        case 7:
            table = "Awards"
        case 8:
            table = "Terms"
        default:
            table = ""
        }
        
        cell = NSCell(textCell: table)
        
        return cell
    }
    
    internal func shouldSelect(recordType: String, record: CKRecord) -> Bool {
        var result = false
        
        switch recordType {
        case "Players":
            if let email = Utility.objectString(cloudObject: record, forKey: "playerUUID") {
                let predicate = NSPredicate(format: "playerUUID = %@", email)
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
            if let playerUUID = Utility.objectString(cloudObject: record, forKey: "playerUUID") {
                let predicate = NSPredicate(format: "playerUUID = %@", playerUUID)
                self.tableViewer.show(recordType: "Players", layout: self.playersLayout, sortAscending: true, predicate: predicate)
                self.tableList.deselectAll(self)
                result = true
            }
        default:
            break
        }
        
        return result
        
    }

    private func setupLayouts() {
        
        playersLayout =
            [ Layout(key: "name",               title: "Name",          width: 80,      alignment: .left,   type: .string,      total: false),
            Layout(key: "nameDate",             title: "Name date",     width: 80,      alignment: .center, type: .date,        total: false),
            Layout(key: "dateCreated",          title: "Date Created",  width: 75,      alignment: .center, type: .date,        total: false),
            Layout(key: "datePlayed",           title: "Last played",   width: 75,      alignment: .center, type: .date,        total: false),
            Layout(key: "email",                title: "Email",         width: -150,    alignment: .left,   type: .string,      total: false),
            Layout(key: "emailDate",            title: "Email date",    width: 80,      alignment: .center, type: .date,        total: false),
            Layout(key: "externalId",           title: "External ID",   width: -80,     alignment: .left,   type: .string,      total: false),
            Layout(key: "totalScore",           title: "Total" ,        width: 50,      alignment: .right,  type: .int,         total: true),
            Layout(key: "gamesPlayed",          title: "Played",        width: 50,      alignment: .right,  type: .int,         total: true),
            Layout(key: "gamesWon",             title: "Won",           width: 50,      alignment: .right,  type: .int,         total: true),
            Layout(key: "handsPlayed",          title: "Hands",         width: 50,      alignment: .right,  type: .int,         total: true),
            Layout(key: "handsMade",            title: "Made",          width: 50,      alignment: .right,  type: .int,         total: true),
            Layout(key: "twosMade",             title: "Twos",          width: 50,      alignment: .right,  type: .int,         total: true),
            Layout(key: "maxScore",             title: "^Score",        width: 50,      alignment: .right,  type: .int,         total: false),
            Layout(key: "maxScoreDate",         title: "Date",          width: 75,      alignment: .center, type: .date,        total: false),
            Layout(key: "maxMade",              title: "^Made",         width: 50,      alignment: .right,  type: .int,         total: false),
            Layout(key: "maxMadeDate",          title: "Date",          width: 75,      alignment: .center, type: .date,        total: false),
            Layout(key: "maxTwos",              title: "^Twos",         width: 50,      alignment: .right,  type: .int,         total: false),
            Layout(key: "maxTwosDate",          title: "Date",          width: 75,      alignment: .center, type: .date,        total: false),
            Layout(key: "syncDate",             title: "Sync date",     width: 75,      alignment: .center, type: .date,        total: false),
            Layout(key: "thumbnailDate",        title: "Thumbnail",     width: 75,      alignment: .center, type: .date,        total: false),
            Layout(key: "playerUUID",           title: "Player UUID",   width: -150,    alignment: .left,   type: .string,      total: false)
        ]
        
        gamesLayout =
            [ Layout(key: "datePlayed",         title: "Last played",   width: 140,      alignment: .center, type: .dateTime,        total: false),
              Layout(key: "deviceName",         title: "Device",        width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "location",           title: "Location",      width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "recordID",           title: "Record ID",     width: -150,    alignment: .left,   type: .string,      total: false),
              Layout(key: "latitude",           title: "Lat",           width: 50,      alignment: .left,   type: .double,      total: false),
              Layout(key: "longitude",          title: "Long",          width: 50,      alignment: .left,   type: .double,      total: false),
              Layout(key: "excludeStats",       title: "Excl",          width: 30,      alignment: .center, type: .bool,        total: false),
              Layout(key: "syncDate",           title: "Sync date",     width: 75,      alignment: .center, type: .date,        total: false),
              Layout(key: "gameUUID",           title: "Game ID",       width: -150,    alignment: .left,   type: .string,      total: false),
              Layout(key: "deviceUUID",         title: "Device ID",     width: -150,    alignment: .left,   type: .string,      total: false) ]

        participantsLayout =
            [ Layout(key: "datePlayed",         title: "Last played",   width: 140,      alignment: .center, type: .dateTime,        total: false),
              Layout(key: "name",               title: "Name",          width: 80,      alignment: .left,   type: .string,      total: false),
              Layout(key: "!playerUUID",        title: "Email",         width: -150,    alignment: .left,   type: .string,      total: false),
              Layout(key: "recordID",           title: "RecordID",      width: -150,    alignment: .left,   type: .string,      total: false),
              Layout(key: "totalScore",         title: "Score" ,        width: 50,      alignment: .right,  type: .int,         total: true),
              Layout(key: "gamesPlayed",        title: "Played",        width: 50,      alignment: .right,  type: .int,         total: true),
              Layout(key: "gamesWon",           title: "Won",           width: 50,      alignment: .right,  type: .int,         total: true),
              Layout(key: "handsPlayed",        title: "Hands",         width: 50,      alignment: .right,  type: .int,         total: true),
              Layout(key: "handsMade",          title: "Made",          width: 50,      alignment: .right,  type: .int,         total: true),
              Layout(key: "twosMade",           title: "Twos",          width: 50,      alignment: .right,  type: .int,         total: true),
              Layout(key: "place",              title: "Position",      width: 50,      alignment: .right,  type: .int,         total: false),
              Layout(key: "playerNumber",       title: "Player",        width: 50,      alignment: .right,  type: .int,         total: false),
              Layout(key: "excludeStats",       title: "Excl",          width: 30,      alignment: .center, type: .bool,        total: false),
              Layout(key: "syncDate",           title: "Sync date",     width: 75,      alignment: .center, type: .date,        total: false),
              Layout(key: "gameUUID",           title: "Game ID",       width: -150,    alignment: .left,   type: .string,      total: false),
              Layout(key: "deviceUUID",         title: "Device ID",     width: -150,    alignment: .left,   type: .string,      total: false),
              Layout(key: "playerUUID",         title: "Player UUID",   width: -150,    alignment: .left,   type: .string,      total: false)
        ]
        
        invitesLayout =
            [ Layout(key: "expires",            title: "Expires",       width: -100,    alignment: .left,   type: .dateTime,    total: false),
              Layout(key: "hostDeviceName",     title: "Host device",   width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "!hostPlayerUUID",    title: "Host email",    width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "hostName",           title: "Host name",     width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "!invitePlayerUUID",  title: "Invite email",  width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "inviteUUID",         title: "Invite UUID",   width: -100,    alignment: .left,   type: .string,      total: false) ]
            
        notificationsLayout =
            [ Layout(key: "!playerUUID",        title: "Email",         width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "message",            title: "Host email",    width: -100,    alignment: .left,   type: .string,      total: false) ]
            
        versionLayout =
            [ Layout(key: "version",            title: "Version",       width: 50,      alignment: .left,   type: .string,      total: false),
              Layout(key: "build",              title: "Build",         width: 30,      alignment: .left,   type: .int,         total: false),
              Layout(key: "infoMessage",        title: "Info",          width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "accessVersion",      title: "Access",        width: 40,      alignment: .left,   type: .string,      total: false),
              Layout(key: "accessMessage",      title: "Message",       width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "syncVersion",        title: "Sync",          width: 40,      alignment: .left,   type: .string,      total: false),
              Layout(key: "syncMessage",        title: "Message",       width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "database",           title: "Database",      width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "rabbitMQUri",        title: "rabbitMQ URI",  width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "LogQueue",           title: "Log queue",     width: -100,    alignment: .left,   type: .string,      total: false) ]

        linksLayout =
            [ Layout(key: "fromEmail",          title: "From email",    width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "!toPlayerUUID",      title: "To email",      width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "fromPlayerUUID",     title: "From UUID",     width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "toPlayerUUID",       title: "To UUID",       width: -100,    alignment: .left,   type: .string,      total: false)]
        
        awardsLayout =
            [ Layout(key: "!playerUUID",        title: "Email",         width: -120,    alignment: .left,   type: .string,      total: false),
              Layout(key: "code",               title: "Code",          width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "awardLevel",         title: "Award level",   width: 100,     alignment: .right,  type: .int,         total: false),
              Layout(key: "count",              title: "Count",         width: 50,      alignment: .right,  type: .int,         total: false),
              Layout(key: "dateAwarded",        title: "Awarded",       width: 150,     alignment: .center, type: .dateTime,   total: false)]
        
        termsLayout =
            [ Layout(key: "deviceName",         title: "Device",        width: -120,    alignment: .left,   type: .string,      total: false),
              Layout(key: "userId",             title: "User ID",       width: -100,    alignment: .left,   type: .string,      total: false),
              Layout(key: "dateAccepted",       title: "Accepted",      width: 150,     alignment: .center, type: .dateTime,    total: false)]
    }
}
