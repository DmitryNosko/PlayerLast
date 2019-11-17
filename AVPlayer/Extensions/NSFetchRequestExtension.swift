//
//  NSFetchRequestExtension.swift
//  AVPlayer
//
//  Created by USER on 11/17/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import CoreData

extension NSFetchRequest {
    
    @objc static func fetchRequest(entity: String, predicate: NSPredicate) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        return request
    }
    
}
