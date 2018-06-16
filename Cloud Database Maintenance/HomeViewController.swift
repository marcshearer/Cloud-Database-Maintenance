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
}

class HomeViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableList: NSTableView!
    @IBOutlet weak var tableView: NSTableView!
    
    var playersLayout: [Layout]!
    var gamesLayout: [Layout]!
    var participantsLayout: [Layout]!
    var tableViewer: TableViewer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableList.delegate = self
        self.tableList.dataSource = self
        self.setupTableList()
        self.setupLayouts()
        
        self.tableViewer = TableViewer(displayTableView: self.tableView)
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
            [ Layout(key: "name",         title: "Name",          width: 80,      alignment: .left,   type: .string),
            Layout(key: "nameDate",     title: "Name date",     width: 80,      alignment: .center, type: .date),
            Layout(key: "dateCreated",  title: "Date Created",  width: 75,      alignment: .center, type: .date),
            Layout(key: "datePlayed",   title: "Last played",   width: 75,      alignment: .center, type: .date),
            Layout(key: "email",        title: "Email",         width: -150,    alignment: .left,   type: .string),
            Layout(key: "emailDate",    title: "Email date",    width: 80,      alignment: .center, type: .date),
            Layout(key: "externalId",   title: "External ID",   width: -80,     alignment: .left,   type: .string),
            Layout(key: "totalScore",   title: "Total" ,        width: 50,      alignment: .right,  type: .int),
            Layout(key: "gamesPlayed",  title: "Played",        width: 50,      alignment: .right,  type: .int),
            Layout(key: "gamesWon",     title: "Won",           width: 50,      alignment: .right,  type: .int),
            Layout(key: "handsPlayed",  title: "Hands",         width: 50,      alignment: .right,  type: .int),
            Layout(key: "handsMade",    title: "Made",          width: 50,      alignment: .right,  type: .int),
            Layout(key: "twosMade",     title: "Twos",          width: 50,      alignment: .right,  type: .int),
            Layout(key: "maxScore",     title: "^Score",        width: 50,      alignment: .right,  type: .int),
            Layout(key: "maxScoreDate", title: "Date",          width: 75,      alignment: .center, type: .date),
            Layout(key: "maxMade",      title: "^Made",         width: 50,      alignment: .right,  type: .int),
            Layout(key: "maxMadeDate",  title: "Date",          width: 75,      alignment: .center, type: .date),
            Layout(key: "maxTwos",      title: "^Twos",         width: 50,      alignment: .right,  type: .int),
            Layout(key: "maxTwosDate",  title: "Date",          width: 75,      alignment: .center, type: .date),
            Layout(key: "syncDate",     title: "Sync date",     width: 75,      alignment: .center, type: .date),
//          Layout(key: "syncGroup",    title: "Sync group",    width: 80,      alignment: .left,   type: .string),
            Layout(key: "thumbnailDate",title: "Thumbnail",     width: 75,      alignment: .center, type: .date)     ]
        
        gamesLayout =
            [ Layout(key: "datePlayed",   title: "Last played",   width: 75,      alignment: .center, type: .date),
              Layout(key: "deviceName",   title: "Device",        width: -100,    alignment: .left,   type: .string),
              Layout(key: "location",     title: "Location",      width: -100,    alignment: .left,   type: .string),
              Layout(key: "latitude",     title: "Lat",           width: 50,      alignment: .left,   type: .double),
              Layout(key: "longitude",    title: "Long",          width: 50,      alignment: .left,   type: .double),
              Layout(key: "excludeStats", title: "Excl",          width: 30,      alignment: .center, type: .bool),
              Layout(key: "syncDate",     title: "Sync date",     width: 75,      alignment: .center, type: .date),
//            Layout(key: "syncGroup",    title: "Sync group",    width: 80,      alignment: .left,   type: .string),
              Layout(key: "gameUUID",     title: "Game ID",       width: -150,    alignment: .left,   type: .string),
              Layout(key: "deviceUUID",   title: "Device ID",     width: -150,    alignment: .left,   type: .string) ]

        participantsLayout =
            [ Layout(key: "datePlayed",   title: "Last played",   width: 75,      alignment: .center, type: .date),
              Layout(key: "name",         title: "Name",          width: 80,      alignment: .left,   type: .string),
              Layout(key: "email",        title: "Email",         width: -150,    alignment: .left,   type: .string),
              Layout(key: "totalScore",   title: "Score" ,        width: 50,      alignment: .right,  type: .int),
              Layout(key: "gamesPlayed",  title: "Played",        width: 50,      alignment: .right,  type: .int),
              Layout(key: "gamesWon",     title: "Won",           width: 50,      alignment: .right,  type: .int),
              Layout(key: "handsPlayed",  title: "Hands",         width: 50,      alignment: .right,  type: .int),
              Layout(key: "handsMade",    title: "Made",          width: 50,      alignment: .right,  type: .int),
              Layout(key: "twosMade",     title: "Twos",          width: 50,      alignment: .right,  type: .int),
              Layout(key: "place",        title: "Position",      width: 50,      alignment: .right,  type: .int),
              Layout(key: "playerNumber", title: "Player",        width: 50,      alignment: .right,  type: .int),
              Layout(key: "excludeStats", title: "Excl",          width: 30,      alignment: .center, type: .bool),
              Layout(key: "syncDate",     title: "Sync date",     width: 75,      alignment: .center, type: .date),
//            Layout(key: "syncGroup",    title: "Sync group",    width: 80,      alignment: .left,   type: .string),
              Layout(key: "gameUUID",     title: "Game ID",       width: -150,    alignment: .left,   type: .string),
              Layout(key: "deviceUUID",   title: "Device ID",     width: -150,    alignment: .left,   type: .string) ]

    }
    
}

public protocol TableViewerDelegate : class {
    
    func status(isBusy: Bool)
    
}

private class TableViewerRequest {
    public var recordType: String!
    public var layout: [Layout]!
    public var sortKey: String!
    public var sortAscending: Bool!
}

class TableViewer : NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    private var current: TableViewerRequest!
    private var pending: TableViewerRequest!
    private var busy = false
    private let displayTableView: NSTableView
    private var recordList: [CKRecord] = []
    private var layout: [Layout]!

    
    public var delegate: TableViewerDelegate?
    
    init(displayTableView: NSTableView) {
        
        self.displayTableView = displayTableView
        
        super.init()
        
        // Setup delegates
        self.displayTableView.dataSource = self
        self.displayTableView.delegate = self

    }
    
    public func show(recordType: String, layout: [Layout], sortKey: String = "", sortAscending: Bool = true) {
        var useTableViewerRequest: TableViewerRequest
        
        if self.busy {
            self.pending = TableViewerRequest()
            useTableViewerRequest = self.pending
        } else {
            self.current = TableViewerRequest()
            useTableViewerRequest = self.current
        }
        
        useTableViewerRequest.recordType = recordType
        useTableViewerRequest.layout = layout
        useTableViewerRequest.sortKey = (sortKey == "" ? layout[0].key : sortKey)
        useTableViewerRequest.sortAscending = sortAscending
        
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
        
        // Set up grid
        self.layout = self.current.layout
        self.setupGrid(displayTableView: displayTableView, layout: self.layout)
        
        let keys = layout.map {$0.key}
        self.setBusy(true)
        
        _ = self.downloadFromCloud(recordType: self.current.recordType, keys: keys,
                                   sortKey: self.current.sortKey, sortAscending: self.current.sortAscending,
                                   downloadAction: { (record) -> Void in
                                        Utility.mainThread {
                                            self.displayTableView.beginUpdates()
                                            self.recordList.append(record)
                                            self.displayTableView.insertRows(at: IndexSet(integer: self.recordList.count - 1), withAnimation: .slideUp)
                                            self.displayTableView.endUpdates()
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
            displayTableView.addTableColumn(tableColumn)
        }
        // Add a blank column
        let tableColumn=NSTableColumn()
        tableColumn.headerCell.title = ""
        displayTableView.addTableColumn(tableColumn)
    }
    
    internal func numberOfRows(in tableView: NSTableView) -> Int {
        return self.recordList.count
    }
    
    internal func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var cell: NSCell!
        
        if let identifier = tableColumn?.identifier.rawValue {
            if let columnNumber = Int(identifier) {
                let column = layout[columnNumber]
                cell = NSCell(textCell: getValue(record: recordList[row], key: column.key, type: column.type))
                cell.alignment = column.alignment
                if column.width <= 0 && cell.cellSize.width > tableColumn!.width {
                    tableColumn?.width = cell.cellSize.width
                }
            }
        }
        return cell
    }
    
    private func getValue(record: CKRecord, key: String, type: VarType) -> String {
        let object = record.object(forKey: key)
        if object == nil {
            return ""
        } else {
            switch type {
            case .string:
                return object as! String
            case .date:
                return Utility.dateString(object as! Date)
            case .int:
                return "\(object!)"
            case .double:
                return "\(object!)"
            case .bool:
                return (object as! Bool == true ? "X" : "")
            }
        }
    }
    
    private func downloadFromCloud(recordType: String,
                                  keys: [String],
                                  sortKey: String,
                                  sortAscending: Bool = true,
                                  downloadAction: @escaping (CKRecord) -> (),
                                  completeAction: @escaping () -> (),
                                  failureAction:  @escaping (String) -> (),
                                  cursor: CKQueryCursor! = nil,
                                  rowsRead: Int = 0) {
        
        var queryOperation: CKQueryOperation
        var predicate: NSPredicate!
        var rowsRead = rowsRead
        
        // Fetch player records from cloud
        let cloudContainer = CKContainer(identifier: "iCloud.MarcShearer.Contract-Whist-Scorecard")
        let publicDatabase = cloudContainer.publicCloudDatabase
        if cursor == nil {
            // First time in - set up the query
            predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: recordType, predicate: predicate)
            let sortDescriptor = NSSortDescriptor(key: sortKey, ascending: sortAscending)
            query.sortDescriptors = [sortDescriptor]
            queryOperation = CKQueryOperation(query: query)
        } else {
            // Continue previous query
            queryOperation = CKQueryOperation(cursor: cursor)
        }
        queryOperation.desiredKeys = keys
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = (rowsRead < 100 ? 30 : 100)
        queryOperation.recordFetchedBlock = { (record) -> Void in
            let cloudObject: CKRecord = record
            rowsRead += 1
            downloadAction(cloudObject)
        }
        
        queryOperation.queryCompletionBlock = { (cursor, error) -> Void in
            if error != nil {
                failureAction("Unable to fetch records from \(recordType) - \(error.debugDescription)")
                return
            }
            
            if cursor != nil && self.pending == nil {
                // More to come - recurse
                _ = self.downloadFromCloud(recordType: recordType, keys: keys, sortKey: sortKey,
                                           downloadAction: downloadAction,
                                           completeAction: completeAction,
                                           failureAction: failureAction,
                                           cursor: cursor, rowsRead: rowsRead)
            } else {
                completeAction()
            }
        }
        
        // Execute the query - disable
        publicDatabase.add(queryOperation)
    }
}

