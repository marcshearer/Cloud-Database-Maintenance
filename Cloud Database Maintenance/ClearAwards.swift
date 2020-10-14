//
//  ClearAwards.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 22/07/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class ClearAwards {
    
    public static let shared = ClearAwards()
    private let iCloud = ICloud()
    
    public func execute(completion: @escaping (String)->()) {
        
        self.iCloud.initialise(recordType: "Awards") { (error) in
            completion(self.iCloud.errorMessage(error))
        }
    }
}
