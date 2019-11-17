//
//  ImageCacheService.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 11/16/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import UIKit

class ImageCacheService {
    private static var imageCache = NSCache<AnyObject, AnyObject>()
    
    static func image(string: String) -> UIImage? {
        return imageCache.object(forKey: string as AnyObject) as? UIImage
    }
    
    static func add(image: UIImage, key: String) {
        imageCache.setObject(image, forKey: key as AnyObject)
    }
}
