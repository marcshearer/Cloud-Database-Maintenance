//
//  Parameters.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 24/08/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Foundation

class Parameters {
    
    class func string(forKey key: String) -> String! {
        return UserDefaults.standard.string(forKey: "\(Utility.appDelegate!.database)-\(key)")
    }
    
    class func integer(forKey key: String) -> Int {
        return UserDefaults.standard.integer(forKey: "\(Utility.appDelegate!.database)-\(key)")
    }
    
    class func bool(forKey key: String) -> Bool! {
        return UserDefaults.standard.bool(forKey: "\(Utility.appDelegate!.database)-\(key)")
    }
    
    class func set(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: "\(Utility.appDelegate!.database)-\(key)")
    }
    
    class func set(_ value: Int, forKey key: String) {
        UserDefaults.standard.set(value, forKey: "\(Utility.appDelegate!.database)-\(key)")
    }
    
    class func set(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: "\(Utility.appDelegate!.database)-\(key)")
    }
}
