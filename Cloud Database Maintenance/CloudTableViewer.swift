//
//  TableViewer.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 28/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

// Note that the Table View must be cell-based (property of the Table View (in the Clip View))

import Cocoa
import CloudKit

enum VarType {
    case string
    case date
    case dateTime
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

public protocol CloudTableViewerDelegate : class {
    
    func status(isBusy: Bool)
    
    func shouldSelect(recordType: String, record: CKRecord) -> Bool
    
    func derivedKey(recordType: String, key: String, record: CKRecord) -> String
    
}

private class CloudTableViewerRequest {
    public var recordType: String!
    public var layout: [Layout]!
    public var sortKey: String!
    public var sortAscending: Bool!
    public var predicate: NSPredicate!
}

class CloudTableViewer : NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    public var dateFormat = "dd/MM/yyyy"
    public var dateTimeFormat = "dd/MM/yyyy HH:mm:ss.ff"
    public var doubleFormat = "%.2f"

    private var current: CloudTableViewerRequest!
    private var pending: CloudTableViewerRequest!
    private var busy = false
    private let displayTableView: NSTableView
    private var records: [CKRecord] = []
    private var layout: [Layout]!
    private var total: [Double?]!
    private var totals = false
    private var additional = 0
    private let iCloud = ICloud()
    
    public var delegate: CloudTableViewerDelegate?
    
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
        var useTableViewerRequest: CloudTableViewerRequest
        var sortKey = sortKey
        
        // Default sort to first non-derived column if unspecified
        if sortKey == "" {
            for layout in layout {
                if layout.key.left(1) != "=" {
                    sortKey = layout.key
                    break
                }
            }
        }
        
        if self.busy {
            // Request in progress - queue this one and try to cancel it
            self.pending = CloudTableViewerRequest()
            self.iCloud.cancel()
            useTableViewerRequest = self.pending
        } else {
            self.current = CloudTableViewerRequest()
            useTableViewerRequest = self.current
        }
        
        useTableViewerRequest.recordType = recordType
        useTableViewerRequest.layout = layout
        useTableViewerRequest.sortKey = sortKey
        useTableViewerRequest.sortAscending = sortAscending
        useTableViewerRequest.predicate = (predicate == nil ? NSPredicate(value: true) : predicate)
        
        if !busy {
            self.showCurrent()
        }
        
    }
    
    private func showCurrent() {
        
        // Remove all rows
        if self.records.count != 0 {
            displayTableView.beginUpdates()
            displayTableView.removeRows(at: IndexSet(integersIn: 0...self.records.count-1), withAnimation: NSTableView.AnimationOptions.slideUp)
            self.records = []
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
                                        self.records.append(record)
                                        self.displayTableView.insertRows(at: IndexSet(integer: self.records.count - 1), withAnimation: .slideUp)
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
                                                self.displayTableView.insertRows(at: IndexSet(integer: self.records.count), withAnimation: .slideUp)
                                                self.displayTableView.endUpdates()
                                            }
                                        }
                                        self.setBusy(false)
                                    }
                                    
        },
                                 failureAction: { (message) -> Void in
                                    Utility.mainThread {
                                        Utility.alertMessage(message)
                                        self.current = nil
                                        self.pending = nil
                                        self.setBusy(false)
                                    }
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
                tableColumn.width = tableColumn.headerCell.cellSize.width + 10
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
        return self.records.count + additional
    }
    
    internal func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        var result: Bool?
        
        if row < self.records.count {
            result = self.delegate?.shouldSelect(recordType: self.current.recordType, record: self.records[row])
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
                if row >= self.records.count {
                    // Total line
                    if self.total[columnNumber] == nil {
                        // Not totalled column
                        cell = NSCell(textCell: "")
                    } else {
                        let format = (column.type == .int ? "%d" : doubleFormat)
                        cell = NSCell(textCell: String(format: format, self.total[columnNumber]!))
                        cell.font = NSFont.boldSystemFont(ofSize: 12)
                    }
                } else {
                    // Normal line
                    var value: String
                    if column.key.left(1) == "=" {
                        value = delegate?.derivedKey(recordType: self.current.recordType, key: column.key.right(column.key.length - 1), record: records[row]) ?? ""
                    } else {
                        value = getValue(record: records[row], key: column.key, type: column.type)
                    }
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
                return Utility.dateString((object as! Date), format: self.dateFormat)
            case .dateTime:
                return Utility.dateString((object as! Date), format: self.dateTimeFormat)
            case .int:
                return "\(object)"
            case .double:
                return String(format: doubleFormat, object as! Double)
            case .bool:
                return (object as! Bool == true ? "X" : "")
            }
        } else {
            return ""
        }
    }
    
    private func getNumericValue(record: CKRecord, key: String, type: VarType) -> Double {
        if let object = record.object(forKey: key) {
            switch type {
            case .int, .double:
                return object as! Double
            default:
                return 0
            }
        } else {
            return 0
        }
    }
}

