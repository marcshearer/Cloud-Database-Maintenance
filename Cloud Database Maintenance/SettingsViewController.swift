//
//  SettingsViewController.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 29/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {

    private var editSettings: Settings!
    private var firstTime = true
    
    @IBOutlet private var backupAutomaticallyButton: NSButton!
    @IBOutlet private var wakeupIntervalTextField: NSTextFieldCell!
    @IBOutlet private weak var minimumBackupIntervalTextField: NSTextFieldCell!
    @IBOutlet private weak var maximumBackupIntervalTextField: NSTextFieldCell!
    @IBOutlet private weak var saveButton: NSButton!
    
    @IBAction func backupAutomaticallyChanged(_ sender: NSButton) {
        self.editSettings.backupAutomatically = (self.backupAutomaticallyButton.intValue != 0)
        self.checkValues()
    }
    
    @IBAction func wakeupIntervalChanged(_ sender: NSTextField) {
        self.editSettings.wakeupIntervalHours = Int(self.wakeupIntervalTextField.intValue)
        self.checkValues()
    }
    
    @IBAction func minimumBackupIntervalChanged(_ sender: NSTextField) {
        self.editSettings.minimumBackupIntervalDays = Int(self.minimumBackupIntervalTextField.intValue)
        self.checkValues()
    }
    
    @IBAction func maximumBackupIntervalChanged(_ sender: NSTextField) {
        self.editSettings.maximumBackupIntervalDays = Int(self.maximumBackupIntervalTextField.intValue)
        self.checkValues()
    }

    @IBAction func saveButtonPressed(_ sender: NSButton) {
        Utility.appDelegate?.settings = self.editSettings.copy() as! Settings
        Utility.appDelegate?.settings.save()
        self.view.window?.close()
        Utility.appDelegate?.clearTimer()
        if (Utility.appDelegate?.settings.backupAutomatically ?? true) {
            Utility.appDelegate?.runPeriodically(every: 60 * 60 * (Utility.appDelegate?.settings.wakeupIntervalHours ?? 6))
        }
        firstTime = true
    }
    
    @IBAction func cancelButtonPressed(_ sender: NSButton) {
        self.view.window?.close()
        firstTime = true
    }
    
    override func viewDidAppear() {
        super.viewDidLoad()
        
        if firstTime {
            self.editSettings = Utility.appDelegate?.settings.copy() as! Settings
            self.reflectValues()
            self.checkValues()
            firstTime = true
        }
        
    }
    
    private func checkValues() {
        self.wakeupIntervalTextField.isEnabled = self.editSettings.backupAutomatically
        self.minimumBackupIntervalTextField.isEnabled = self.editSettings.backupAutomatically
        self.maximumBackupIntervalTextField.isEnabled = self.editSettings.backupAutomatically
        
        if !self.editSettings.backupAutomatically {
            self.editSettings.wakeupIntervalHours = 0
            self.editSettings.minimumBackupIntervalDays = 0
            self.editSettings.maximumBackupIntervalDays = 0
            self.reflectValues()
            self.saveButton.isEnabled = true
        } else {
            if self.editSettings.wakeupIntervalHours <= 0 ||
                    self.editSettings.minimumBackupIntervalDays <= 0 ||
                    self.editSettings.maximumBackupIntervalDays < self.editSettings.minimumBackupIntervalDays {
                self.saveButton.isEnabled = false
            } else {
                self.saveButton.isEnabled = true
            }
        }
    }
    
    private func reflectValues() {
        self.backupAutomaticallyButton.intValue = (self.editSettings.backupAutomatically ? 1 : 0)
        self.wakeupIntervalTextField.intValue = Int32(self.editSettings.wakeupIntervalHours)
        self.minimumBackupIntervalTextField.intValue = Int32(self.editSettings.minimumBackupIntervalDays)
        self.maximumBackupIntervalTextField.intValue = Int32(self.editSettings.maximumBackupIntervalDays)
    }
    
}
