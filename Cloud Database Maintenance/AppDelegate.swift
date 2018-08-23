//
//  AppDelegate.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 12/06/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    public var backupDateMenuItem: NSMenuItem!
    public var backupMenuItem: NSMenuItem!
    private var databaseMaintenanceWindowController: NSWindowController!
    private var backupWindowController: NSWindowController!
    private var settingsWindowController: NSWindowController!
    private var timer = Timer()
    public var settings = Settings()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
         if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("spade"))
        }
        constructMenu()
        
        // Load settings
        settings.load()
        
        // Run periodically if selected
        if (self.settings.backupAutomatically ?? true) {
            runPeriodically(every: 60 * 60 * (settings.wakeupIntervalHours ?? 6))
        }
    }
    
    func runPeriodically(every timeInterval: Int) {
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
    
    func constructMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let lastBackup = UserDefaults.standard.string(forKey: "backupDate") ?? "No previous backup"
        let backupTitleMenuItem = menu.addItem(withTitle: "Last backup", action: nil, keyEquivalent: "")
        backupTitleMenuItem.isEnabled = false
        self.backupDateMenuItem = menu.addItem(withTitle: lastBackup, action: nil, keyEquivalent: "")
        self.backupDateMenuItem.isEnabled = false
        menu.addItem(NSMenuItem.separator())
        self.backupMenuItem = menu.addItem(withTitle: "Backup database", action: #selector(AppDelegate.backup(_:)), keyEquivalent: "B")
        menu.addItem(withTitle: "Database maintenance", action: #selector(AppDelegate.maintenance(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Settings", action: #selector(AppDelegate.settings(_:)), keyEquivalent: "")
        // menu.addItem(NSMenuItem.separator())
        // menu.addItem(withTitle: "Backup if needed", action: #selector(AppDelegate.conditionalBackup(_:)), keyEquivalent: "")
        // menu.addItem(withTitle: "Reset backup date", action: #selector(AppDelegate.setLastBackupDate(_:)), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
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
            returnedWindowController = mainStoryboard.instantiateController(withIdentifier: menubarWindowIdentifier) as! NSWindowController
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

