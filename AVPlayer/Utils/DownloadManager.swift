//
//  DownloadManager.swift
//  AVPlayer
//
//  Created by USER on 11/17/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import UIKit

class DownloadManager: NSObject {
    
    static var imageURLstring: String?
    
    static func loadImageUsingURLString(string: String) -> UIImage? {
        imageURLstring = string
        let url = URL(string: string)
        var image: UIImage?
        
        if let imagefromCache = ImageCacheService.image(string: string) {
            image = imagefromCache
            return image
        }
        
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                return
            }
            DispatchQueue.main.async {
                let imageToCache = UIImage(data: data!)
                if self.imageURLstring == string {
                    image = imageToCache
                }
                ImageCacheService.add(image: imageToCache!, key: string)
            }
            }.resume()
        return image
    }
    
    
    //TODO add methods downloadAudi Video
}
