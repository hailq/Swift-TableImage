//
//  AppRecord.swift
//  SwiftLazyTableImage
//
//  Created by Hai Luong Quang on 9/17/14.
//  Copyright (c) 2014 Hai Luong Quang. All rights reserved.
//

import Foundation
import UIKit

class AppRecord {
    var appName: String = ""
    var artist: String = ""
    var imageURLString: String = ""
    var appURLString: String = ""
    var appIcon: UIImage?
    
    init() {
        self.appIcon = nil
    }
}