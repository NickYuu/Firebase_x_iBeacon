//
//  PreferenceName.swift
//  FirebaseWithiBeacon
//
//  Created by YU on 2016/12/23.
//  Copyright © 2016年 YU. All rights reserved.
//

import Foundation

struct PreferenceName<Type>: RawRepresentable {
    typealias RawValue = String
    
    var rawValue: String
    
    init?(rawValue: PreferenceName.RawValue) {
        self.rawValue = rawValue
    }
}

struct PreferenceNames {
    
    static let userName = PreferenceName<String>(rawValue: "userName")!
    
}
