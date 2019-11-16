//
//  CaptureVideoViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 11/4/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CaptureVideoViewController: UIViewController {

    
    @IBOutlet weak var videoView: UIView!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: String = ""
    let coreDataManager = CoreDataManager()
    var customPodcastItem: PodcastItem?
    
    //MARK: - playerElements
    
    let controlsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    let pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "pause")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        button.isHidden = true
        button.addTarget(self, action: #selector(handlePause), for: .touchUpInside)
        return button
    }()
    
    let videoLenghtLable: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textAlignment = NSTextAlignment.right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let currentTimeLable: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let videoSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = UIColor.red
        slider.maximumTrackTintColor = UIColor.white
        slider.addTarget(self, action: #selector(handleSliderChange), for: .valueChanged)
        return slider
    }()
    
    let cancelVideoButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "cancel")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        return button
    }()
    
    let saveVideoButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "saveBLACK")
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()
    
    //MARK: - VCLifeCycle methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpPlayerView(url: videoURL)
        controlsContainerView.frame = self.view.bounds
        self.view.addSubview(controlsContainerView)
        configerateControlsContainerView()
        startPlaying()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if playerLayer != nil {
            playerLayer.frame = videoView.bounds
        }
    }
    
    //MARK: - Selectors
    var isPlaying = false
    
    @objc func handlePause() {
        if isPlaying {
            player?.pause()
            pausePlayButton.setImage(UIImage(named: "play"), for: .normal)
        } else {
            player?.play()
            pausePlayButton.setImage(UIImage(named: "pause"), for: .normal)
        }
        isPlaying = !isPlaying
    }
    
    @objc func handleSliderChange() {
        
        if let duration = player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(videoSlider.value) * totalSeconds
            
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }
    
    @objc func handleSave() {
        let alert = UIAlertController(title: "Create podcast", message: "Fill all fields", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Add title"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Add Description"
        }
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { (al) in
            self.dismiss(animated: true) {
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (al) in
            
            let textFields = alert.textFields
            let titleTF = textFields?.first
            let descriptionTF = textFields?.last
            
            if titleTF?.text != "" && descriptionTF?.text != "" {
                let title = titleTF?.text
                let desct = descriptionTF?.text
                self.downloadVideoLinkAndCreateAsset(self.videoURL, title: title!, description: desct!)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func downloadVideoLinkAndCreateAsset(_ videoLink: String, title: String, description: String) {
        guard let videoURL = URL(string: videoLink) else { return }
        print("videoURL to download = \(videoURL)")
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
                                        print("Video asset created")
                                        let options = PHFetchOptions()
                                        var allPodcasts = [PHAsset]()
                                        
                                        options.sortDescriptors = [ NSSortDescriptor(key: "creationDate", ascending: false) ]
                                        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
                                        let photos = PHAsset.fetchAssets(with: options)
                                        photos.enumerateObjects { (asset, idx, stop) in
                                            allPodcasts.append(asset)
                                        }
                                        
                                        let asset = allPodcasts.first
                                        guard(asset!.mediaType == PHAssetMediaType.video)
                                            else {
                                                print("Not a valid video media type")
                                                return
                                        }
                                        
                                        PHCachingImageManager().requestAVAsset(forVideo: asset!, options: nil) { (avAsset, audioMix, info) in
                                            let asset = avAsset as!AVURLAsset
                                            print("captured assets url created = \(asset.url.absoluteString)")
                                            
                                            let mediaType = MediaType(rawValue: MediaType.customType.rawValue)
                                            let progressStatus = ProgressStatus(rawValue: ProgressStatus.new.rawValue)
                                            
                                            let itemToSave = PodcastItem(identifier: self.customPodcastItem!.identifier, itemTitle: title, itemDescription: description, itemPubDate: "", itemDuration: "", itemURL: asset.url.absoluteString, itemImage: "", itemAuthor: "", itemIsDownloaded: false, itemIsDeleted: false, itemMediaType: mediaType!, itemProgressStatus: progressStatus!)
                                            self.coreDataManager.addItem(item: itemToSave)
                                            self.dismiss(animated: true) {
                                            }
                                        }
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
    
    @objc func handleCancel() {
        player.pause()
        dismiss(animated: true) {
        }
    }
    
    //MARK: - Player
    
    func startPlaying() {
        player.play()
        player?.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        
        let interval = CMTime(value: 1, timescale: 2)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (progressTime) in
            
            let time = CMTime()
            let seconds = CMTimeGetSeconds(progressTime)
            let totalSeconds = time.durationTexForTime(time: progressTime)
            self.currentTimeLable.text = "\(totalSeconds)"
            
            if let duration = self.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                self.videoSlider.value = Float(seconds / durationSeconds)
            }
        })
    }
    
    var counter = 0
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            controlsContainerView.backgroundColor = UIColor.clear
            
            if counter == 0 {
                pausePlayButton.isHidden = true
                videoSlider.isHidden = true
                currentTimeLable.isHidden = true
                videoLenghtLable.isHidden = true
                cancelVideoButton.isHidden = true
                saveVideoButton.isHidden = true
                isPlaying = true
                counter += 1
            }
            
            if let duration = player?.currentItem?.duration {
                let time = CMTime()
                let totalSeconds = time.durationTexForTime(time: duration)
                videoLenghtLable.text = "\(totalSeconds)"
            }
        }
    }
    
    //MARK: - PlayerConfig
    
    func configerateControlsContainerView() {
        controlsContainerView.addSubview(pausePlayButton)
        controlsContainerView.addSubview(videoLenghtLable)
        controlsContainerView.addSubview(videoSlider)
        controlsContainerView.addSubview(currentTimeLable)
        controlsContainerView.addSubview(cancelVideoButton)
        controlsContainerView.addSubview(saveVideoButton)
        
        setUpPauseButtonContraints()
        setUpVideoLenghtLabelConstraints()
        setUpVideoSliderConstraints()
        setUpCurrentTimeLableConstraints()
        setCancelVideoButtonContraints()
        setSaveVideoButtonContraints()
    }
    
    private func setUpPlayerView(url: String) {
        if let url = NSURL(string: url) {
            player = AVPlayer(url: url as URL)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resize
            videoView.layer.addSublayer(playerLayer)
        }
    }
    
    //MARK: - touches
    var timer: Timer?
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 3,
                                     target: self,
                                     selector: #selector(hideAllButtons),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    func stop(){
        if(timer != nil){timer!.invalidate()}
    }
    
    @objc func hideAllButtons() {
        pausePlayButton.isHidden = true
        videoSlider.isHidden = true
        currentTimeLable.isHidden = true
        videoLenghtLable.isHidden = true
        cancelVideoButton.isHidden = true
        saveVideoButton.isHidden = true
        stop()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        print("BeganTouch")
        if pausePlayButton.isHidden == true {
            pausePlayButton.isHidden = false
            videoSlider.isHidden = false
            currentTimeLable.isHidden = false
            videoLenghtLable.isHidden = false
            cancelVideoButton.isHidden = false
            saveVideoButton.isHidden = false
            startTimer()
        } else {
            pausePlayButton.isHidden = true
            videoSlider.isHidden = true
            currentTimeLable.isHidden = true
            videoLenghtLable.isHidden = true
            cancelVideoButton.isHidden = true
            saveVideoButton.isHidden = true
        }
    }
    
    //MARK: Constraints
    
    private func setUpPauseButtonContraints() {
        pausePlayButton.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        pausePlayButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        pausePlayButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setUpVideoLenghtLabelConstraints() {
        videoLenghtLable.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
        videoLenghtLable.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        videoLenghtLable.widthAnchor.constraint(equalToConstant: 50).isActive = true
        videoLenghtLable.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }
    
    private func setUpVideoSliderConstraints() {
        videoSlider.rightAnchor.constraint(equalTo: videoLenghtLable.safeAreaLayoutGuide.leftAnchor, constant: -8).isActive = true
        videoSlider.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        videoSlider.leftAnchor.constraint(equalTo: currentTimeLable.safeAreaLayoutGuide.rightAnchor, constant: 8).isActive = true
        videoSlider.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    private func setUpCurrentTimeLableConstraints() {
        currentTimeLable.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 8).isActive = true
        currentTimeLable.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        currentTimeLable.widthAnchor.constraint(equalToConstant: 50).isActive = true
        currentTimeLable.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }
    
    private func setCancelVideoButtonContraints() {
        cancelVideoButton.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
        cancelVideoButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        cancelVideoButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        cancelVideoButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
    }

    private func setSaveVideoButtonContraints() {
        saveVideoButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 8).isActive = true
        saveVideoButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        saveVideoButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        saveVideoButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
    }
}
