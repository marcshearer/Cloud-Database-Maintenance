//
//  TableViewer.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 28/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa
import CloudKit

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
                                 sortKey: [self.current.sortKey],
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
                return Utility.dateString((object as! Date))
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

