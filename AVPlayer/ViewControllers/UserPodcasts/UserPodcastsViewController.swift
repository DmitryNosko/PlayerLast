//
//  UserPodcastsViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/28/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit
import Photos

class UserPodcastsViewController: UITableViewController {

    let VIDEO_CELL_IDENTIFIER: String = "Cell"
    let coreDataManager = CoreDataManager()
    private var displayedCustomItems: [PodcastItem]?
    var podcasts = [PHAsset]()
    
    var infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.text = "Custom podcasts doesn't exist, click to CAMERA to add new."
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpInfoLabelConstraints()
        displayedCustomItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", "customType"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayedCustomItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", "customType"))
        if let items = displayedCustomItems, items.count == 0 {
            tableView.separatorStyle = .none
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getAssetFromPhoto()
        self.tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let videoItems = displayedCustomItems else {
            return 0
        }
        return videoItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VIDEO_CELL_IDENTIFIER, for: indexPath) as! CustomPodcastTableViewCell
        
        let item = displayedCustomItems![indexPath.row]
        cell.videoTitleLabel.text = item.itemTitle
        cell.videoDescriptionLabel.text = item.itemDescription
        
        let options = PHFetchOptions()
        var allPodcasts = [PHAsset]()
        
        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        let photos = PHAsset.fetchAssets(with: options)
        photos.enumerateObjects { (asset, idx, stop) in
            allPodcasts.append(asset)
        }
        
        for asset in allPodcasts {

            if asset.mediaType == PHAssetMediaType.video {
                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
                    let asset2 = avAsset as? AVURLAsset
                    
                    if asset2?.url.absoluteString == item.itemURL {
                        let width: CGFloat = 500
                        let height: CGFloat = 500
                        let size = CGSize(width:width, height:height)
                        
                        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: nil) { (image, userInfo) -> Void in
                            DispatchQueue.main.async {
                                cell.videoImageView.image = image
                            }
                        }
                    }
                }
            }
            
        }
        
        return cell
    }

    var chousenAsset: PHAsset?
    
    func findAssetByURL(url: String) {
        let options = PHFetchOptions()
        var allPodcasts = [PHAsset]()

        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        let photos = PHAsset.fetchAssets(with: options)
        photos.enumerateObjects { (asset, idx, stop) in
            allPodcasts.append(asset)
        }
        
        for asset in allPodcasts {
            guard(asset.mediaType == PHAssetMediaType.video)
                else {
                    print("Not a valid video media type")
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let itemToDelete = displayedCustomItems?[indexPath.row]
            coreDataManager.deleteItem(item: itemToDelete!)
            
            // delte video
            
            let options = PHFetchOptions()
            var allPodcasts = [PHAsset]()
            
            options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
            options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            let photos = PHAsset.fetchAssets(with: options)
            photos.enumerateObjects { (asset, idx, stop) in
                allPodcasts.append(asset)
            }
            
            for asset in allPodcasts {
                if asset.mediaType == PHAssetMediaType.video {
                    PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
                        let asset2 = avAsset as? AVURLAsset
                        
                        if asset2?.url.absoluteString == itemToDelete?.itemURL {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
                            }) { (boo, error) in
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                                print(error as Any)
                            }
                        }
                    }
                }
            }
            
            //delete video
            
            displayedCustomItems?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.reloadData()
            if let items = displayedCustomItems, items.count == 0 {
                tableView.separatorStyle = .none
                infoLabel.isHidden = false
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "playVideoFromCameraRoll", sender: self)
    }
    
    //MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playVideoFromCameraRoll" {
            let destinationVC: CaptureVideoViewController = segue.destination as! CaptureVideoViewController
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let item = displayedCustomItems![indexPath.row]
                destinationVC.videoURL = item.itemURL
            }
        }
    }
    
    //MARK: - Photos
    
    
    
    func getAssetFromPhoto() {

        let options = PHFetchOptions()
        var allPodcasts = [PHAsset]()
        let customItemsURLS = coreDataManager.customItemsURlS()
        
        for item in customItemsURLS {
            print("i'm customItemURl = \(item)")
        }
        
        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        let photos = PHAsset.fetchAssets(with: options)
        photos.enumerateObjects { (asset, idx, stop) in
            allPodcasts.append(asset)
        }

        for asset in allPodcasts {
            guard(asset.mediaType == PHAssetMediaType.video)
                else {
                    print("Not a valid video media type")
                    return
            }

            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
                let asset2 = avAsset as? AVURLAsset
                for ciu in customItemsURLS {
                    if ciu == asset2?.url.absoluteString {
                        self.podcasts.append(asset)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }

            }
        }
    }

    //MARK: - SetUp's
    
    func setUpTableView() {
        self.tableView.addSubview(infoLabel)
        self.tableView.register(CustomPodcastTableViewCell.self, forCellReuseIdentifier: VIDEO_CELL_IDENTIFIER)
        self.tableView.estimatedRowHeight = 200
    }
    
    func setUpInfoLabelConstraints() {
        infoLabel.centerXAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        infoLabel.centerYAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerYAnchor).isActive = true
        infoLabel.leadingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        infoLabel.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
    }
}
