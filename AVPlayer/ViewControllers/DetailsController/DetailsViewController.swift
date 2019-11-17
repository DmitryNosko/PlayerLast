//
//  DetailsViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/28/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit
import Photos

class DetailsViewController: UIViewController {

    private struct Constants {
        //constants
    }
    
    var podcastImage: UIImage?
    var podcastItem: PodcastItem?
    let coreDataManager = CoreDataManager()
    var podcastURL = ""
    
    @IBOutlet weak var podcastStreamButton: UIButton!
    @IBOutlet weak var podcastDownloadButton: UIButton!
    @IBOutlet weak var podcastImageView: UIImageView!
    @IBOutlet weak var podcastAuthorLabel: UILabel!
    @IBOutlet weak var podcastDurationLabel: UILabel!
    @IBOutlet weak var podcastPubDateLabel: UILabel!
    @IBOutlet weak var podastIsDownloadedLabel: UILabel!
    @IBOutlet weak var podcastTitleLabel: UILabel!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    
    @IBAction func downloadResourceAction(_ sender: Any) {
        if podcastItem?.itemURL.last == "4" {
            podcastDownloadButton.setTitle("Video loading", for: .normal)
            downloadVideoIntoAsset(podcastItem!.itemURL)
        } else {
            podcastDownloadButton.setTitle("Audio loading", for: .normal)
            downloadAudioIntoAsset(podcastItem!.itemURL)
        }
    }
    
    @IBAction func streamAudio(_ sender: Any) {
        if podcastItem?.itemURL.last != "4" {
            performSegue(withIdentifier: "showAudioPlayer", sender: self)
        } else {
            performSegue(withIdentifier: "presentResource", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        podcastImageView.layer.cornerRadius = podcastImageView.frame.width / 2
        podcastImageView.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coreDataManager.updateItemURL(item: podcastItem!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let videoURL = URL(string: podcastItem!.itemURL) else {
            return
        }
        
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        if FileManager.default.fileExists(atPath: documentsDirectoryURL.appendingPathComponent(videoURL.lastPathComponent).path) {
            podastIsDownloadedLabel.text = "downloaded"
            podcastDownloadButton.isHidden = true
        } else {
            podastIsDownloadedLabel.text = "not downloaded"
            podcastDownloadButton.isHidden = false
        }
        
        if let image = podcastImage {
            podcastImageView.image = image
        } else {
            if let image = ImageCacheService.image(string: podcastItem!.itemImage) {
                podcastImageView.image = image
            } else {
                URLSession.shared.dataTask(with: URL(string: podcastItem!.itemImage)!) { (data, response, error) in
                    if error != nil {
                        return
                    }
                    DispatchQueue.main.async {
                        let downloadedImage = UIImage(data: data!)
                        self.podcastImageView.image = downloadedImage
                        self.view.reloadInputViews()
                    }
                    }.resume()
            }
        }

        podcastAuthorLabel.text = podcastItem?.itemAuthor
        podcastDurationLabel.text = podcastItem?.itemDuration
        podcastPubDateLabel.text = podcastItem?.itemPubDate
        podcastTitleLabel.text = podcastItem?.itemTitle
        podcastDescriptionLabel.text = podcastItem?.itemDescription
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentResource" {
            let destinationVC: VideoPlayerViewController = segue.destination as! VideoPlayerViewController
            guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let urlTILoad = documentsDirectoryURL.appendingPathComponent(podcastItem!.itemURL)
            if FileManager.default.fileExists(atPath: urlTILoad.path) {
                destinationVC.videoURL = urlTILoad.absoluteString
            } else {
                destinationVC.videoURL = podcastItem!.itemURL
            }
        } else if segue.identifier == "showAudioPlayer" {
            let destinationVC: AudioPlayerViewController = segue.destination as! AudioPlayerViewController
            guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let urlTILoad = documentsDirectoryURL.appendingPathComponent(podcastItem!.itemURL)
            if FileManager.default.fileExists(atPath: urlTILoad.path) {
                destinationVC.audioURL = urlTILoad.absoluteString
                destinationVC.podcstPlayerImage = podcastImage
            } else {
                destinationVC.audioURL = podcastItem!.itemURL
                destinationVC.podcstPlayerImage = podcastImage
            }
        }
    }
    
    func downloadAudioIntoAsset(_ videoLink: String) {
        guard let audioURL = URL(string: videoLink) else { return }
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        if !FileManager.default.fileExists(atPath: documentsDirectoryURL.appendingPathComponent(audioURL.lastPathComponent).path) {
            URLSession.shared.downloadTask(with: audioURL) {
                (location, response, error) -> Void in
                let destinationURL = documentsDirectoryURL.appendingPathComponent(response?.suggestedFilename ?? audioURL.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: location!, to: destinationURL)
                    self.podcastItem?.itemURL = audioURL.lastPathComponent
                    self.podcastItem?.itemIsDownloaded = true
                    self.performSelector(onMainThread: #selector(self.videoWasDownloadedHandler), with: nil, waitUntilDone: false)
                } catch let error as NSError {
                    print("can't move file error: \(error.localizedDescription)")
                }
                print(response as Any)
                }.resume()
        } else {
            print("File already exists at destination url")
        }
    }
    
    //MARK: downloading
    
    func downloadVideoIntoAsset(_ videoLink: String) {
        guard let videoURL = URL(string: videoLink) else { return }
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        if !FileManager.default.fileExists(atPath: documentsDirectoryURL.appendingPathComponent(videoURL.lastPathComponent).path) {
            URLSession.shared.downloadTask(with: videoURL) {
                (location, response, error) -> Void in
                guard let location = location else { return }
                let destinationURL = documentsDirectoryURL.appendingPathComponent(response?.suggestedFilename ?? videoURL.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    PHPhotoLibrary.requestAuthorization({ (authorizationStatus: PHAuthorizationStatus) -> Void in
                        if authorizationStatus == .authorized {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationURL)}) { completed, error in
                                    if completed {
                                        self.podcastItem?.itemURL = videoURL.lastPathComponent
                                        self.podcastItem?.itemIsDownloaded = true
                                        self.performSelector(onMainThread: #selector(self.videoWasDownloadedHandler), with: nil, waitUntilDone: false)
                                    } else {
                                        print("error to load video")
                                    }
                            }
                        }
                    })
                } catch { print(error) }
                }.resume()
        } else {
            print("File already exists at destination url")
        }
    }
    
    @objc func videoWasDownloadedHandler() {
        podastIsDownloadedLabel.text = "downloaded"
        podcastDownloadButton.isHidden = true
        podcastStreamButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
    }
    
    
    
    
    
}
