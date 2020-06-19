//
//  Config.swift
//  Contract Whist Scorecard
//
//  Created by Marc Shearer on 25/09/2017.
//  Copyright © 2017 Marc Shearer. All rights reserved.
//

import Foundation

class Config {
    
    // iCloud database identifer
    public static let iCloudIdentifier = "iCloud.MarcShearer.Contract-Whist-Scorecard"
    
    // Columns for record IDs
    public static let recordIdKeys = ["Games"           : ["datePlayed", "deviceName", "gameUUID"],
                                      "Invites"         : ["hostName", "hostPlayerUUID", "invitePlayerUUID", "inviteUUID"],
                                      "Links"           : ["fromPlayer", "toPlayer"],
                                      "Notifications"   : ["playerUUID"],
                                      "Participants"    : ["datePlayed", "playerUUID", "gameUUID"],
                                      "Players"         : ["email"],
                                      "Version"         : []]
    
    public static let backupDirectoryDateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
    public static let backupDateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
    public static let recordIdDateFormat = "yyyy-MM-dd-HH-mm-ss"

}

