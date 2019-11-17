//
//  CustomImageView.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/24/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import UIKit

//class CustomImageView: UIImageView {
//    
//    var imageURLstring: String?
//    
//    func loadImageUsingURLString(string: String) {
//        imageURLstring = string
//        
//        let url = URL(string: string)
//        self.image = nil
//        
//        if let imagefromCache = ImageCacheService.image(string: string) {
//            self.image = imagefromCache
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url!) { (data, response, error) in
//            if error != nil {
//                return
//            }
//            
//            DispatchQueue.main.async {
//                let imageToCache = UIImage(data: data!)
//                if self.imageURLstring == string {
//                    self.image = imageToCache
//                }
//                ImageCacheService.add(image: imageToCache!, key: string)
//            }
//            
//        }.resume()
//    }
//
//}
