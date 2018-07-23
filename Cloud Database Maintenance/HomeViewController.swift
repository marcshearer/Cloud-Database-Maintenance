//
//  HomeViewController.swift
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

class HomeViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, TableViewerDelegate {
    
    private var playersLayout: [Layout]!
    private var gamesLayout: [Layout]!
    private var participantsLayout: [Layout]!
    private var tableViewer: TableViewer!

    @IBOutlet weak var tableList: NSTableView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var backupButton: NSButtonCell!
    
    @IBAction func backupMenuItemSelected(_ sender: Any) {
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "BackupSegue"), sender: sender)
    }
    
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

public protocol TableViewerDelegate : class {
    
    func status(isBusy: Bool)
    
    func shouldSelect(recordType: String, record: CKRecord) -> Bool
    
}

private class TableViewerRequest {
    public var recordType: String!
    public var layout: [Layout]!
    public var sortKey: String!
    public var sortAscending: Bool!
    public var predicate: NSPredicate!
}

class TableViewer : NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    private var current: TableViewerRequest!
    private var pending: TableViewerRequest!
    private var busy = false
    private let displayTableView: NSTableView
    private var recordList: [CKRecord] = []
    private var layout: [Layout]!
    private var total: [Int?]!
    private var totals = false
    private var additional = 0
    private let iCloud = ICloud()
    
    public var delegate: TableViewerDelegate?
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    init(displayTableView: NSTableView) {
        
        self.displayTableView = displayTableView
        
        super.init()
        
        // Setup delegates
        self.displayTableView.dataSource = self
        self.displayTableView.delegate = self

    }
    
    public func show(recordType: String, layout: [Layout], sortKey: String = "", sortAscending: Bool = true, predicate: NSPredicate? = nil) {
        var useTableViewerRequest: TableViewerRequest
        
        if self.busy {
            // Request in progress - queue this one and try to cancel it
            self.pending = TableViewerRequest()
            self.iCloud.cancel()
            useTableViewerRequest = self.pending
        } else {
            self.current = TableViewerRequest()
            useTableViewerRequest = self.current
        }
        
        useTableViewerRequest.recordType = recordType
        useTableViewerRequest.layout = layout
        useTableViewerRequest.sortKey = (sortKey == "" ? layout[0].key : sortKey)
        useTableViewerRequest.sortAscending = sortAscending
        useTableViewerRequest.predicate = (predicate == nil ? NSPredicate(value: true) : predicate)
        
        if !busy {
            self.showCurrent()
        }
        
    }
    
    private func showCurrent() {
        
        // Remove all rows
        if self.recordList.count != 0 {
            displayTableView.beginUpdates()
            displayTableView.removeRows(at: IndexSet(integersIn: 0...self.recordList.count-1), withAnimation: NSTableView.AnimationOptions.slideUp)
            self.recordList = []
            displayTableView.reloadData()
            displayTableView.endUpdates()
        }
        additional = 0
        
        // Set up grid
        self.layout = self.current.layout
        self.setupGrid(displayTableView: displayTableView, layout: self.layout)
        
        let keys = layout.map {$0.key}
        self.setBusy(true)
        
        _ = self.iCloud.download(recordType: self.current.recordType,
                                   keys: keys,
                                   sortKey: self.current.sortKey,
                                   sortAscending: self.current.sortAscending,
                                   predicate: self.current.predicate,
                                   downloadAction: { (record) -> Void in
                                        Utility.mainThread {
                                           
                                            self.displayTableView.beginUpdates()
                                            self.recordList.append(record)
                                            self.displayTableView.insertRows(at: IndexSet(integer: self.recordList.count - 1), withAnimation: .slideUp)
                                            self.displayTableView.endUpdates()
                                            
                                            for columnNumber in 0..<self.layout.count {
                                                let column = self.layout[columnNumber]
                                                if column.total {
                                                    self.total[columnNumber] = self.total[columnNumber]! + self.getNumericValue(record: record, key: column.key, type: column.type)
                                                }
                                            }
                                        }
                                   },
                                   completeAction: {
                                        if self.pending != nil {
                                            Utility.mainThread {
                                                self.current = self.pending
                                                self.pending = nil
                                                self.showCurrent()
                                            }
                                        } else {
                                            if self.totals {
                                                // Add a total line
                                                Utility.mainThread {
                                                    self.displayTableView.beginUpdates()
                                                    self.additional = 1
                                                    self.displayTableView.insertRows(at: IndexSet(integer: self.recordList.count), withAnimation: .slideUp)
                                                    self.displayTableView.endUpdates()
                                                }
                                            }
                                            self.setBusy(false)
                                        }
                                    
                                    },
                                   failureAction: { (message) -> Void in
                                        self.current = nil
                                        self.pending = nil
                                        self.setBusy(false)
                                    })
    }
    
    private func setBusy(_ busy: Bool) {
        self.delegate?.status(isBusy: busy)
        self.busy = busy
    }
    
    private func setupGrid(displayTableView: NSTableView, layout: [Layout]) {
        // Remove any existing columns
        for tableColumn in displayTableView.tableColumns {
            displayTableView.removeTableColumn(tableColumn)
        }
        self.total = []
        self.totals = false
        
        for index in 0..<layout.count {
            let column = layout[index]
            let tableColumn = NSTableColumn()
            let headerCell = NSTableHeaderCell()
            headerCell.title = column.title
            headerCell.alignment = column.alignment
            tableColumn.headerCell = headerCell
            if column.width < 0 && tableColumn.headerCell.cellSize.width > abs(column.width) {
                tableColumn.width = tableColumn.headerCell.cellSize.width
            } else {
                tableColumn.width = abs(column.width)
            }
            tableColumn.identifier = NSUserInterfaceItemIdentifier("\(index)")
            self.displayTableView.addTableColumn(tableColumn)
            self.total.append(column.total ? 0 : nil)
            self.totals = true
        }
        // Add a blank column
        let tableColumn=NSTableColumn()
        tableColumn.headerCell.title = ""
        displayTableView.addTableColumn(tableColumn)
    }
    
    internal func numberOfRows(in tableView: NSTableView) -> Int {
        return self.recordList.count + additional
    }
    
    internal func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        var result: Bool?
        
        if row < self.recordList.count {
            result = self.delegate?.shouldSelect(recordType: self.current.recordType, record: self.recordList[row])
        }
        
        if result != nil {
            return result!
        } else {
            return false
        }
    }
    
    internal func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }

    internal func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var cell: NSCell!
        
        if let identifier = tableColumn?.identifier.rawValue {
            if let columnNumber = Int(identifier) {
                let column = layout[columnNumber]
                if row >= self.recordList.count {
                    // Total line
                    if self.total[columnNumber] == nil {
                        // Not totalled column
                        cell = NSCell(textCell: "")
                    } else {
                        cell = NSCell(textCell: "\(self.total[columnNumber]!)")
                        cell.font = NSFont.boldSystemFont(ofSize: 12)
                    }
                } else {
                    // Normal line
                    let value = getValue(record: recordList[row], key: column.key, type: column.type)
                    cell = NSCell(textCell: value)
                }
                cell.alignment = column.alignment
                if column.width <= 0 && cell.cellSize.width > tableColumn!.width {
                    tableColumn?.width = cell.cellSize.width
                }
            }
        }
        return cell
    }
    
    private func getValue(record: CKRecord, key: String, type: VarType) -> String {
        if let object = record.object(forKey: key) {
            switch type {
            case .string:
                return object as! String
            case .date:
                return Utility.dateString(object as! Date)
            case .int:
                return "\(object)"
            case .double:
                return "\(object)"
            case .bool:
                return (object as! Bool == true ? "X" : "")
            }
        } else {
            return ""
        }
    }
    
    private func getNumericValue(record: CKRecord, key: String, type: VarType) -> Int {
        if let object = record.object(forKey: key) {
            switch type {
            case .int, .double:
                return object as! Int
            default:
                return 0
            }
        } else {
            return 0
        }
    }
}

