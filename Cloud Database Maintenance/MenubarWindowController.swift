//
//  MenubarWindowController.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 23/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Cocoa

class MenubarWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
