//
//  AssetsService.swift
//  AVPlayer
//
//  Created by USER on 11/17/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import Photos

class AssetsService {
    
    private struct Constants {
        static let kCreationDate = "creationDate"
        static let kErrorMessage = "error to load video"
        static let kEmptyString = ""
        static let kFileExistMessage = "File already exists at destination url"
    }
    
    private static let coreDataManager = CoreDataManager()
    
    static var chousenAsset: PHAsset?
    
    static func allAssets() -> [PHAsset] {
        let options = PHFetchOptions()
        var podcasts = [PHAsset]()
        options.sortDescriptors = [ NSSortDescriptor(key: Constants.kCreationDate, ascending: false) ]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        let photos = PHAsset.fetchAssets(with: options)
        photos.enumerateObjects { (asset, idx, stop) in
            podcasts.append(asset)
        }
        return podcasts
    }
    
    static func asset(url: String) {
        let allPodcasts = allAssets()
        
        for asset in allPodcasts {
            guard(asset.mediaType == PHAssetMediaType.video)
                else {
                    return
            }
            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
                let asset2 = avAsset as? AVURLAsset
                if asset2?.url.absoluteString == url {
                    self.chousenAsset = asset
                }
            }
        }
    }
    
    static func assetImage(url: String, assets: [PHAsset]) -> UIImage {
        var imageToReturn: UIImage?
        for asset in assets {
            if asset.mediaType == PHAssetMediaType.video {
                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
                    let asset2 = avAsset as? AVURLAsset
                    
                    if asset2?.url.absoluteString == url {
                        let width: CGFloat = 500
                        let height: CGFloat = 500
                        let size = CGSize(width:width, height:height)
                        
                        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: nil) { (image, userInfo) -> Void in
                            DispatchQueue.main.async {
                                imageToReturn = image
                            }
                        }
                    }
                }
            }
        }
        
        return imageToReturn!
    }
    
    static func deleteAsset(url: String, assets: [PHAsset]) {
        for asset in assets {
            if asset.mediaType == PHAssetMediaType.video {
                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
                    let asset2 = avAsset as? AVURLAsset
                    
                    if asset2?.url.absoluteString == url {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
                        }) { (boo, error) in
                            print(error as Any)
                        }
                    }
                }
            }
        }
    }
    
    static func customAssets() -> [PHAsset] {
        var assetsToReturn = [PHAsset]()
        let customItemsURLS = coreDataManager.customItemsURlS()
        
        let allPodcasts = allAssets()
        for asset in allPodcasts {
            if asset.mediaType == PHAssetMediaType.video {
                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
                    let asset2 = avAsset as? AVURLAsset
                    for ciu in customItemsURLS {
                        if ciu == asset2?.url.absoluteString {
                            assetsToReturn.append(asset)
                        }
                    }
                    
                }
            }
        }
        return assetsToReturn
    }
    
    static func addAsset(destinationURL: URL, title: String, description: String, customItemID: UUID) {
        PHPhotoLibrary.requestAuthorization({ (authorizationStatus: PHAuthorizationStatus) -> Void in
            if authorizationStatus == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationURL)}) { completed, error in
                        if completed {
                            
                            let asset = AssetsService.allAssets().first
                            
                            if asset!.mediaType == PHAssetMediaType.video {
                                PHCachingImageManager().requestAVAsset(forVideo: asset!, options: nil) { (avAsset, audioMix, info) in
                                    let asset = avAsset as!AVURLAsset
                                    
                                    let mediaType = MediaType(rawValue: MediaType.customType.rawValue)
                                    let progressStatus = ProgressStatus(rawValue: ProgressStatus.new.rawValue)
                                    
                                    let itemToSave = PodcastItem(identifier: customItemID, itemTitle: title, itemDescription: description, itemPubDate: Constants.kEmptyString, itemDuration: Constants.kEmptyString, itemURL: asset.url.absoluteString, itemImage: Constants.kEmptyString, itemAuthor: Constants.kEmptyString, itemIsDownloaded: false, itemIsDeleted: false, itemMediaType: mediaType!, itemProgressStatus: progressStatus!)
                                    self.coreDataManager.addItem(item: itemToSave)
                                }
                            }
                        } else {
                            print(Constants.kErrorMessage)
                        }
                }
            }
        })
    }
    
}
