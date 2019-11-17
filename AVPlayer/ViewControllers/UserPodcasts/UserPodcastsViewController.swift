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

    private struct Constants {
        static let kUserCellIdentifier = "Cell"
        static let kInfoLabelText = "Custom podcasts doesn't exist, click to CAMERA to add new."
        static let kMediaTypeCustom = "customType"
        static let kCreationDate = "creationDate"
        static let kPlayVideoIdentifier = "playVideoFromCameraRoll"
        static let kLoadedTimeRanges = "currentItem.loadedTimeRanges"
        static let kEmptyString = ""
    }
    
    let coreDataManager = CoreDataManager()
    private var displayedCustomItems: [PodcastItem]?
    var podcasts = [PHAsset]()
    
    var infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        label.text = Constants.kInfoLabelText
        label.font = UIFont.boldSystemFont(ofSize: 19)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpInfoLabelConstraints()
        displayedCustomItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", Constants.kMediaTypeCustom))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurateVK()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        podcasts = AssetsService.customAssets()
        //libo
        //podcasts.append(contentsOf: customAssets())
        self.tableView.reloadData()
    }
    
    //MARK: TableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let videoItems = displayedCustomItems else {
            return 0
        }
        return videoItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.kUserCellIdentifier, for: indexPath) as! CustomPodcastTableViewCell
        let item = displayedCustomItems![indexPath.row]
        let allPodcasts = AssetsService.allAssets()
        cell.videoTitleLabel.text = item.itemTitle
        cell.videoDescriptionLabel.text = item.itemDescription
        cell.videoImageView.image = AssetsService.assetImage(url: item.itemImage, assets: allPodcasts)
        return cell
    }
    
    //MARK: TableViewDelegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let itemToDelete = displayedCustomItems?[indexPath.row]
            coreDataManager.deleteItem(item: itemToDelete!)
            let allPodcasts = AssetsService.allAssets()
            AssetsService.deleteAsset(url: itemToDelete!.itemURL, assets: allPodcasts)
            displayedCustomItems?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.reloadSections(IndexSet(integer: 0), with: .left)
            if let items = displayedCustomItems, items.count == 0 {
                tableView.separatorStyle = .none
                infoLabel.isHidden = false
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Constants.kPlayVideoIdentifier, sender: self)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.kPlayVideoIdentifier {
            let destinationVC: CaptureVideoViewController = segue.destination as! CaptureVideoViewController
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let item = displayedCustomItems![indexPath.row]
                destinationVC.videoURL = item.itemURL
            }
        }
    }
    
    //MARK: - Assets

//    var chousenAsset: PHAsset?
//    
//    func allAssets() -> [PHAsset] {
//        let options = PHFetchOptions()
//        var podcasts = [PHAsset]()
//        options.sortDescriptors = [ NSSortDescriptor(key: Constants.kCreationDate, ascending: false) ]
//        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
//        let photos = PHAsset.fetchAssets(with: options)
//        photos.enumerateObjects { (asset, idx, stop) in
//            podcasts.append(asset)
//        }
//        return podcasts
//    }
//    
//    func asset(url: String) {
//        let allPodcasts = allAssets()
//        
//        for asset in allPodcasts {
//            guard(asset.mediaType == PHAssetMediaType.video)
//                else {
//                    return
//            }
//            PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
//                let asset2 = avAsset as? AVURLAsset
//                if asset2?.url.absoluteString == url {
//                    self.chousenAsset = asset
//                }
//            }
//        }
//    }
//    
//    func assetImage(url: String, assets: [PHAsset]) -> UIImage {
//        var imageToReturn: UIImage?
//        for asset in assets {
//            if asset.mediaType == PHAssetMediaType.video {
//                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
//                    let asset2 = avAsset as? AVURLAsset
//                    
//                    if asset2?.url.absoluteString == url {
//                        let width: CGFloat = 500
//                        let height: CGFloat = 500
//                        let size = CGSize(width:width, height:height)
//                        
//                        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: nil) { (image, userInfo) -> Void in
//                            DispatchQueue.main.async {
//                                imageToReturn = image
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        return imageToReturn!
//    }
//    
//    func deleteAsset(url: String, assets: [PHAsset]) {
//        for asset in assets {
//            if asset.mediaType == PHAssetMediaType.video {
//                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
//                    let asset2 = avAsset as? AVURLAsset
//                    
//                    if asset2?.url.absoluteString == url {
//                        PHPhotoLibrary.shared().performChanges({
//                            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
//                        }) { (boo, error) in
//                            DispatchQueue.main.async {
//                                self.tableView.reloadSections(IndexSet(integer: 0), with: .left)
//                            }
//                            print(error as Any)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    func customAssets() -> [PHAsset] {
//        var assetsToReturn = [PHAsset]()
//        let customItemsURLS = coreDataManager.customItemsURlS()
//        
//        let allPodcasts = allAssets()
//        for asset in allPodcasts {
//            if asset.mediaType == PHAssetMediaType.video {
//                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, audioMix, info) in
//                    let asset2 = avAsset as? AVURLAsset
//                    for ciu in customItemsURLS {
//                        if ciu == asset2?.url.absoluteString {
//                            assetsToReturn.append(asset)
//                            DispatchQueue.main.async {
//                                self.tableView.reloadData()
//                            }
//                        }
//                    }
//                    
//                }
//            }
//        }
//        return assetsToReturn
//    }

    //MARK: - SetUp's
    
    func configurateVK() {
        displayedCustomItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", Constants.kMediaTypeCustom))
        if let items = displayedCustomItems, items.count == 0 {
            tableView.separatorStyle = .none
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }
    }
    
    func setUpTableView() {
        self.tableView.addSubview(infoLabel)
        self.tableView.register(CustomPodcastTableViewCell.self, forCellReuseIdentifier: Constants.kUserCellIdentifier)
        self.tableView.estimatedRowHeight = 200
    }
    
    //MARK: - Constraints
    
    func setUpInfoLabelConstraints() {
        infoLabel.centerXAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        infoLabel.centerYAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerYAnchor).isActive = true
        infoLabel.leadingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        infoLabel.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
    }
}
