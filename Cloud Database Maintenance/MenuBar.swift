//
//  MenuBar.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 28/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa

class MenuBar {
    
    public class func setBackupTitle(title: String, enabled: Bool? = nil) {
        Utility.appDelegate?.backupMenuItem.title = title
        if let enabled = enabled {
            Utility.appDelegate?.backupMenuItem.isEnabled = enabled
        }
    }
    
    public class func setBackupDate(backupDate: Date) {
        // Save string and interval versions of date
        let backupDateString = Utility.dateString(backupDate, format: "EEEE dd MMMM YYYY HH:mm", localized: true)
        let backupDateInterval = Int(backupDate.timeIntervalSinceReferenceDate)
        UserDefaults.standard.set(backupDateString, forKey: "backupDate")
        UserDefaults.standard.set(backupDateInterval, forKey: "backupInterval")
        
        // Show on menu bar
        Utility.appDelegate?.backupDateMenuItem.title = backupDateString
    }
    
    public class func checkLastBackup() {
        let settings = Utility.appDelegate?.settings
        let minimumGap = (settings?.minimumBackupIntervalDays ?? 1) * 60 * 60 * 24
        let maximumGap = (settings?.maximumBackupIntervalDays ?? 14) * 60 * 60 * 24 * 7       // Backup at least once a week
        
        let nowInterval = Int(Date().timeIntervalSinceReferenceDate)
        let lastBackupInterval = UserDefaults.standard.integer(forKey: "backupInterval")
        
        if (nowInterval - lastBackupInterval) < minimumGap {
            // Have a backup less than the minimum gap old
            
        } else if lastBackupInterval == 0 || (nowInterval - lastBackupInterval) > maximumGap {
            // No previous backup or haven't had one for more than maximum gap - backup now
            MenuBar.backupNow()
            
        } else {
            // Read last game and compare date
            let iCloud = ICloud()
            var lastPlayed: Date?
            
            iCloud.download(recordType: "Games",
                            keys: ["datePlayed"],
                            sortKey: ["datePlayed"],
                            sortAscending: false,
                            resultsLimit: 1,
                            downloadAction: { (record) in
                                                // Got last date
                                                lastPlayed = Utility.objectDate(cloudObject: record, forKey: "datePlayed")
                                            },
                            completeAction: {
                                                if (lastPlayed != nil && lastBackupInterval < Int(lastPlayed!.timeIntervalSinceReferenceDate)) {
                                                    MenuBar.backupNow()
                                                }
                                            },
                            failureAction: { (message) in
                                                Utility.alertMessage("Error getting last game (\(message))")
                                            })
        }
    }
    
    private class func backupNow() {
        let backup = Backup()
        backup.backup(resetMessage: true, disableMenu: true, endTable: { (recordType, ok, message) in
            if !ok {
                Utility.alertMessage(message)
            }
        })
    }
}
