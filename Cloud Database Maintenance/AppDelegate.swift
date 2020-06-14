//
//  AppDelegate.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 12/06/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    private var backupTitleMenuItem: NSMenuItem!
    public var backupDateMenuItem: NSMenuItem!
    public var backupMenuItem: NSMenuItem!
    public var createLinksMenuItem: NSMenuItem!
    public var createLinksStatusMenuItem: NSMenuItem!
    public var emailToUUIDMenuItem: NSMenuItem!
    public var emailToUUIDStatusMenuItem: NSMenuItem!
    public var clearPrivateSettingsMenuItem: NSMenuItem!
    public var clearPrivateSettingsStatusMenuItem: NSMenuItem!
    public var createReadableRecordIDsMenuItem: NSMenuItem!
    public var createReadableRecordIDsStatusMenuItem: NSMenuItem!
    public var checkDuplicateGamesMenuItem: NSMenuItem!
    public var checkDuplicateGamesStatusMenuItem: NSMenuItem!
    public var checkDuplicateParticipantsMenuItem: NSMenuItem!
    public var checkDuplicateParticipantsStatusMenuItem: NSMenuItem!
    private var databaseMaintenanceWindowController: NSWindowController!
    private var backupWindowController: NSWindowController!
    private var settingsWindowController: NSWindowController!
    private var timer: Timer!
    public var settings = Settings()
    public var database = "unknown"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
         if let button = self.statusItem.button {
            button.image = NSImage(named:NSImage.Name("unknown"))
        }
        dummyMenu()
        
        // Check which database we are connected to
        let iCloud = ICloud()
        iCloud.getDatabaseIdentifier { (success, errorMessage, database) in
            
            if success {
                Utility.mainThread {
                    
                    // Store database identifier
                    self.database = database!
                    
                    // Load settings
                    self.settings.load()
                    
                    // Build proper menu
                    self.constructMenu()
                    
                    // Update menu bar image
                    if let button = self.statusItem.button {
                        if self.database == "production" {
                            button.image = NSImage(named:NSImage.Name("spade"))
                        } else if self.database == "development" {
                            button.image = NSImage(named:NSImage.Name("diamond"))
                        } else {
                            button.image = NSImage(named:NSImage.Name("unknown"))
                        }
                    }
                    
                    // Run periodically if selected
                    if (self.settings.backupAutomatically ?? true) {
                        self.runPeriodically(every: 60 * 60 * (self.settings.wakeupIntervalHours ?? 6))
                    }
                }
            } else {
                self.backupTitleMenuItem.title = "Failed to access database"
            }
        }
    }
    
    func clearTimer() {
        self.timer = nil
    }
    
    func runPeriodically(every timeInterval: Int) {
        // Run it now
        self.conditionalBackup(self)
        
        // Set it to run periodically
        self.timer = Timer.scheduledTimer(
            timeInterval: TimeInterval(timeInterval),
            target: self,
            selector: #selector(AppDelegate.conditionalBackup(_:)),
            userInfo: nil,
            repeats: true)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func dummyMenu() {
        // Initial menu while ascertaining which database we are connecting to
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        self.backupTitleMenuItem = menu.addItem(withTitle: "Getting database...", action: nil, keyEquivalent: "")
        self.backupTitleMenuItem.isEnabled = false
        
        statusItem.menu = menu
    }
    
    func constructMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        
        let lastBackup = Parameters.string(forKey: "backupDate") ?? "No previous backup"
        self.backupTitleMenuItem = menu.addItem(withTitle: "Last backup (\(self.database))", action: nil, keyEquivalent: "")
        self.backupTitleMenuItem.isEnabled = false
        self.backupDateMenuItem = menu.addItem(withTitle: lastBackup, action: nil, keyEquivalent: "")
        self.backupDateMenuItem.isEnabled = false
        menu.addItem(NSMenuItem.separator())
        self.backupMenuItem = menu.addItem(withTitle: "Backup database", action: #selector(AppDelegate.backup(_:)), keyEquivalent: "B")
        menu.addItem(withTitle: "Database maintenance", action: #selector(AppDelegate.maintenance(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        self.createLinksMenuItem = menu.addItem(withTitle: "Create links entries", action: #selector(AppDelegate.createLinks(_:)), keyEquivalent: "")
        self.createLinksStatusMenuItem = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        self.createLinksStatusMenuItem.isHidden = true
        self.createLinksStatusMenuItem.isEnabled = false
        
        self.emailToUUIDMenuItem = menu.addItem(withTitle: "Convert email to UUID", action: #selector(AppDelegate.confirmEmailToUUID(_:)), keyEquivalent: "")
        self.emailToUUIDStatusMenuItem = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        self.emailToUUIDStatusMenuItem.isHidden = true
        self.emailToUUIDStatusMenuItem.isEnabled = false
        
       self.clearPrivateSettingsMenuItem = menu.addItem(withTitle: "Clear private settings", action: #selector(AppDelegate.confirmClearPrivateSettings(_:)), keyEquivalent: "")
        self.clearPrivateSettingsStatusMenuItem = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        self.clearPrivateSettingsStatusMenuItem.isHidden = true
        self.clearPrivateSettingsStatusMenuItem.isEnabled = false
        
        self.createReadableRecordIDsMenuItem = menu.addItem(withTitle: "Create readable record IDs", action: #selector(AppDelegate.confirmCreateReadableRecordIDs(_:)), keyEquivalent: "")
        self.createReadableRecordIDsStatusMenuItem = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        self.createReadableRecordIDsStatusMenuItem.isHidden = true
        self.createReadableRecordIDsStatusMenuItem.isEnabled = false
        
        menu.addItem(NSMenuItem.separator())
        
        self.checkDuplicateGamesMenuItem = menu.addItem(withTitle: "Check duplicate games", action: #selector(AppDelegate.checkDuplicateGames(_:)), keyEquivalent: "")
        self.checkDuplicateGamesStatusMenuItem = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        self.checkDuplicateGamesStatusMenuItem.isHidden = true
        self.checkDuplicateGamesStatusMenuItem.isEnabled = false
        
        self.checkDuplicateParticipantsMenuItem = menu.addItem(withTitle: "Check duplicate participants", action: #selector(AppDelegate.checkDuplicateParticipants(_:)), keyEquivalent: "")
        self.checkDuplicateParticipantsStatusMenuItem = menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
        self.checkDuplicateParticipantsStatusMenuItem.isHidden = true
        self.checkDuplicateParticipantsStatusMenuItem.isEnabled = false

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Settings", action: #selector(AppDelegate.settings(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    func popupConfirm(title: String, action: Selector, cancelAction: Selector) {
        let menu = NSMenu()
        menu.addItem(withTitle: title, action: action, keyEquivalent: "")
        menu.addItem(withTitle: "Cancel", action: cancelAction, keyEquivalent: "")
        NSSound(named: NSSound.Name(rawValue: "Submarine"))?.play()
        self.statusItem.popUpMenu(menu)
    }
    
    func showStatus(option: String, status: String) {
        Utility.mainThread {
            let menu = NSMenu()
            menu.addItem(withTitle: "\(option) completion: \(status)", action: #selector(AppDelegate.doNothing(_:)), keyEquivalent: "")
            NSSound(named: NSSound.Name(rawValue: "Frog"))?.play()
            self.statusItem.popUpMenu(menu)
        }
    }
    
    @objc private func doNothing(_ sender: Any?) {
        
    }
        
    @objc func backup(_ sender: Any?) {
        backupWindowController = self.showMenubarWindow(menubarWindowController: self.backupWindowController, windowIdentifier: "BackupWindow")
    }
    
    @objc func maintenance(_ sender: Any?) {
        databaseMaintenanceWindowController = self.showMenubarWindow(menubarWindowController: self.databaseMaintenanceWindowController, windowIdentifier: "MaintenanceWindow")
    }
    
    @objc func settings(_ sender: Any?) {
        settingsWindowController = self.showMenubarWindow(menubarWindowController: self.settingsWindowController, windowIdentifier: "SettingsWindow")
    }
    
    @objc func createLinks(_ sender: Any?) {
        self.createLinksMenuItem.title = "Creating links..."
        self.createLinksMenuItem.isEnabled = false
        Utility.mainThread {
            CreateLinks.shared.execute { message in
                self.createLinksMenuItem.title = "Create links entries"
                self.createLinksMenuItem.isEnabled = true
                self.createLinksStatusMenuItem.title = "   Last status: \(message)"
                self.createLinksStatusMenuItem.isHidden = false
                self.showStatus(option: "Create links entries", status: message)
            }
        }
    }
    
    @objc func confirmEmailToUUID(_ sender: Any?) {
        self.popupConfirm(title: "Confirm (irreversible) convert email to UUID", action: #selector(AppDelegate.emailToUUID(_:)), cancelAction: #selector(AppDelegate.resetEmailToUUID(_:)))
    }
    
    @objc func emailToUUID(_ sender: Any?) {
        self.emailToUUIDMenuItem.title = "Converting email to UUID..."
        self.emailToUUIDMenuItem.isEnabled = false
        Utility.mainThread {
            EmailToUUID.shared.execute { message in
                self.resetEmailToUUID(message)
            }
        }
    }
    
    @objc func resetEmailToUUID(_ sender: Any?) {
        self.emailToUUIDMenuItem.title = "Convert email to UUID"
        self.emailToUUIDMenuItem.isEnabled = true
        if let message = sender as? String {
            self.emailToUUIDStatusMenuItem.title = "   Last status: \(message)"
            self.emailToUUIDStatusMenuItem.isHidden = false
            self.showStatus(option: "Convert email to UUID", status: message)
        } else {
            self.emailToUUIDStatusMenuItem.isHidden = true
        }
    }
        
    @objc func confirmClearPrivateSettings(_ sender: Any?) {
        self.popupConfirm(title: "Confirm (irreversible) clear private settings", action: #selector(AppDelegate.clearPrivateSettings(_:)), cancelAction: #selector(AppDelegate.resetClearPrivateSettings(_:)))
    }
    
    @objc func resetClearPrivateSettings(_ sender: Any?) {
        self.clearPrivateSettingsMenuItem.title = "Clear private settings"
        self.clearPrivateSettingsMenuItem.isEnabled = true
        if let message = sender as? String {
            self.clearPrivateSettingsStatusMenuItem.title = "   Last status: \(message)"
            self.clearPrivateSettingsStatusMenuItem.isHidden = false
            self.showStatus(option: "Clear private settings", status: message)
        } else {
            self.clearPrivateSettingsStatusMenuItem.isHidden = true
        }
    }
    
    @objc func clearPrivateSettings(_ sender: Any?) {
        self.clearPrivateSettingsMenuItem.title = "Clearing private settings..."
        self.clearPrivateSettingsMenuItem.isEnabled = false
        Utility.mainThread {
            ClearPrivateSettings.shared.execute { message in
                self.resetClearPrivateSettings(message)
            }
        }
    }
    
    @objc func confirmCreateReadableRecordIDs(_ sender: Any?) {
        self.popupConfirm(title: "Confirm (irreversible) create readable Record IDs", action: #selector(AppDelegate.createReadableRecordIDs(_:)), cancelAction: #selector(AppDelegate.resetCreateReadableRecordIDs(_:)))
    }
    
    @objc func createReadableRecordIDs(_ sender: Any?) {
        self.createReadableRecordIDsMenuItem.title = "Creating readable Record IDs..."
        self.createReadableRecordIDsMenuItem.isEnabled = false
        Utility.mainThread {
            ReadableRecordIDs.shared.execute { message in
                self.resetCreateReadableRecordIDs(message)
            }
        }
    }
    
    @objc func resetCreateReadableRecordIDs(_ sender: Any?) {
        self.createReadableRecordIDsMenuItem.title = "Create readable Record IDs"
        self.createReadableRecordIDsMenuItem.isEnabled = true
        if let message = sender as? String {
            self.createReadableRecordIDsStatusMenuItem.title = "   Last status: \(message)"
            self.createReadableRecordIDsStatusMenuItem.isHidden = false
            self.showStatus(option: "Create readable Record IDs", status: message)
        } else {
            self.createReadableRecordIDsStatusMenuItem.isHidden = true
        }
    }
    
    @objc func checkDuplicateGames(_ sender: Any?) {
        self.checkDuplicateGamesMenuItem.title = "Checking duplicate games..."
        self.checkDuplicateGamesMenuItem.isEnabled = false
        Utility.mainThread {
            CheckDuplicateGames.shared.execute { message in
                self.checkDuplicateGamesMenuItem.title = "Check duplicate games"
                self.checkDuplicateGamesMenuItem.isEnabled = true
                self.checkDuplicateGamesStatusMenuItem.title = "   Last status: \(message)"
                self.checkDuplicateGamesStatusMenuItem.isHidden = false
                self.showStatus(option: "Check duplicate games", status: message)
            }
        }
    }
    
    @objc func checkDuplicateParticipants(_ sender: Any?) {
        self.checkDuplicateParticipantsMenuItem.title = "Checking duplicate participants..."
        self.checkDuplicateParticipantsMenuItem.isEnabled = false
        Utility.mainThread {
            CheckDuplicateParticipants.shared.execute { message in
                self.checkDuplicateParticipantsMenuItem.title = "Check duplicate participants"
                self.checkDuplicateParticipantsMenuItem.isEnabled = true
                self.checkDuplicateParticipantsStatusMenuItem.title = "   Last status: \(message)"
                self.checkDuplicateParticipantsStatusMenuItem.isHidden = false
                self.showStatus(option: "Check duplicate participants", status: message)
            }
        }
    }
    
    @objc func conditionalBackup(_ sender: Any?) {
        MenuBar.checkLastBackup()
    }
    
    @objc func setLastBackupDate(_ sender: Any?) {
        if let backupDate = Utility.dateFromString("01/01/2018", format: "dd/MM/yyyy") {
            MenuBar.setBackupDate(backupDate: backupDate)
        }
    }
    
    func showMenubarWindow(menubarWindowController: NSWindowController! = nil, windowIdentifier: String) -> NSWindowController {
        var returnedWindowController: NSWindowController!
        
        if menubarWindowController == nil {
            let mainStoryboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
            let menubarWindowIdentifier = NSStoryboard.SceneIdentifier(rawValue: windowIdentifier)
            returnedWindowController = mainStoryboard.instantiateController(withIdentifier: menubarWindowIdentifier) as? NSWindowController
        } else {
            returnedWindowController = menubarWindowController
        }
        returnedWindowController.showWindow(self)
        returnedWindowController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return returnedWindowController
    }
    
    func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "backupAutomatically":          true,
            "wakeupIntervalHours":          6,
            "minimumBackupIntervalDays":    1,
            "maximumBackupIntervalDays":    14,
         ])
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Cloud_Database_Maintenance")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
   
// MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

