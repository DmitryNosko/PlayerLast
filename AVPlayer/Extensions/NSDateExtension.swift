//
//  NSDateExtension.swift
//  AVPlayer
//
//  Created by USER on 11/17/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation

extension Date {
    
    private static let kDateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    
    static func dateFromString(str: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = kDateFormat
        let date = dateFormatter.date(from: str)
        return date!
    }
}
