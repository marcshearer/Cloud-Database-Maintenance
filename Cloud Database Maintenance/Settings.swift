//
//  Settings.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 29/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Foundation

class Settings: NSObject, NSCopying {
    
    var backupAutomatically: Bool!
    var wakeupIntervalHours: Int!
    var minimumBackupIntervalDays: Int!
    var maximumBackupIntervalDays: Int!
    
    init(backupAutomatically: Bool! = false,
         wakeupIntervalHours: Int! = 0,
         minimumBackupIntervalDays: Int! = 0,
         maximumBackupIntervalDays: Int! = 0) {
        
        self.backupAutomatically = backupAutomatically
        self.wakeupIntervalHours = wakeupIntervalHours
        self.minimumBackupIntervalDays = minimumBackupIntervalDays
        self.maximumBackupIntervalDays = maximumBackupIntervalDays
    }
    
    public func load() {
        self.backupAutomatically = UserDefaults.standard.bool(forKey: "backupAutomatically")
        self.wakeupIntervalHours = UserDefaults.standard.integer(forKey: "wakeupIntervalHours")
        self.minimumBackupIntervalDays = UserDefaults.standard.integer(forKey: "minimumBackupIntervalDays")
        self.maximumBackupIntervalDays = UserDefaults.standard.integer(forKey: "maximumBackupIntervalDays")
    }
    
    public func save() {
        UserDefaults.standard.set(self.backupAutomatically, forKey: "backupAutomatically")
        UserDefaults.standard.set(self.wakeupIntervalHours, forKey: "wakeupIntervalHours")
        UserDefaults.standard.set(self.minimumBackupIntervalDays, forKey: "minimumBackupIntervalDays")
        UserDefaults.standard.set(self.maximumBackupIntervalDays, forKey: "maximumBackupIntervalDays")
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = Settings(backupAutomatically: self.backupAutomatically,
                            wakeupIntervalHours: self.wakeupIntervalHours,
                            minimumBackupIntervalDays: self.minimumBackupIntervalDays,
                            maximumBackupIntervalDays: self.maximumBackupIntervalDays)
        return copy
    }
}
