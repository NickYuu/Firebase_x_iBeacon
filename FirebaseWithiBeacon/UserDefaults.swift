//
//  UserDefaults.swift
//  FirebaseWithiBeacon
//
//  Created by YU on 2016/12/23.
//  Copyright © 2016年 YU. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    subscript(key: PreferenceName<String>) -> String? {
        set { set(newValue, forKey: key.rawValue) }
        get { return string(forKey: key.rawValue) }
    }
    
    
}
