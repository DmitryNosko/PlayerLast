//
//  DownloadManager.swift
//  AVPlayer
//
//  Created by USER on 11/17/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import UIKit
import Photos

class DownloadManager: NSObject {
    
    private struct Constants {
        static let kErrorMessage = "error to load video"
        static let kEmptyString = ""
        static let kFileExistMessage = "File already exists at destination url"
    }
    
    private let coreDataManager = CoreDataManager()
    
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
    
    static func downloadVideoAndCreateAsset(videoLink: String, title: String, description: String, customItemID: UUID) {
        guard let videoURL = URL(string: videoLink) else { return }
        let documentsDirectoryURL = FileManager.documentDirectory()
        
        if !FileManager.default.fileExists(atPath: documentsDirectoryURL.appendingPathComponent(videoURL.lastPathComponent).path) {
            
            URLSession.shared.downloadTask(with: videoURL) {(location, response, error) -> Void in
                guard let location = location else { return }
                
                let destinationURL = documentsDirectoryURL.appendingPathComponent(response?.suggestedFilename ?? videoURL.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    AssetsService.addAsset(destinationURL: destinationURL, title: title, description: description, customItemID: customItemID)
                    
                } catch { print(error) }
                }.resume()
        } else {
            print(Constants.kFileExistMessage)
        }
    }
    
    
    //TODO add methods downloadAudi Video
}
