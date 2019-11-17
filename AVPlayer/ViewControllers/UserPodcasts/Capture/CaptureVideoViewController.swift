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
    
    private struct Constants {
        static let kEmptyString = ""
        static let kPauseImage = "pause"
        static let kDefaultLenghtValue = "00:00"
        static let kVolumeImage = "volume"
        static let kCancelImage = "cancel"
        static let kPlayImage = "play"
        static let kLoadedTimeRanges = "currentItem.loadedTimeRanges"
        static let kSaveBlackImage = "saveBLACK"
        static let kAlertTitle = "Create podcast"
        static let kAlertMessage = "Be sure to fill out all fields"
        static let kAddTitleTF = "Add title"
        static let kAddDescriptionTF = "Add description"
        static let kTFCloseButton = "Close"
        static let kTFSaveButton = "Save"
    }
    
    @IBOutlet weak var videoView: UIView!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: String = Constants.kEmptyString
    let coreDataManager = CoreDataManager()
    var customPodcastItem: PodcastItem?
    
    //MARK: - playerElements
    
    let controlsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    let pausePlayButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: Constants.kPauseImage)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        button.isHidden = true
        button.addTarget(self, action: #selector(handlePause), for: .touchUpInside)
        return button
    }()
    
    let videoLenghtLable: UILabel = {
        let label = UILabel()
        label.text = Constants.kDefaultLenghtValue
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textAlignment = NSTextAlignment.right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let currentTimeLable: UILabel = {
        let label = UILabel()
        label.text = Constants.kDefaultLenghtValue
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
        let image = UIImage(named: Constants.kCancelImage)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        return button
    }()
    
    let saveVideoButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: Constants.kSaveBlackImage)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpPlayerView(url: videoURL)
        configerateControlsContainerView()
        startPlaying()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if playerLayer != nil {
            playerLayer.frame = videoView.bounds
        }
    }
    
    //MARK: - Player actions
    
    var isPlaying = false
    
    @objc func handlePause() {
        if isPlaying {
            player?.pause()
            pausePlayButton.setImage(UIImage(named: Constants.kPlayImage), for: .normal)
        } else {
            player?.play()
            pausePlayButton.setImage(UIImage(named: Constants.kPauseImage), for: .normal)
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
        let alert = UIAlertController(title: Constants.kAddTitleTF, message: Constants.kAlertMessage, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = Constants.kAddTitleTF
        }
        alert.addTextField { (textField) in
            textField.placeholder = Constants.kAddDescriptionTF
        }
        
        alert.addAction(UIAlertAction(title: Constants.kTFCloseButton, style: .cancel, handler: { (al) in
            self.dismiss(animated: true) {
            }
        }))
        
        alert.addAction(UIAlertAction(title: Constants.kTFSaveButton, style: .default, handler: { (al) in
            
            let textFields = alert.textFields
            let titleTF = textFields?.first
            let descriptionTF = textFields?.last
            
            if titleTF?.text != Constants.kEmptyString && descriptionTF?.text != Constants.kEmptyString {
                let title = titleTF?.text
                let desct = descriptionTF?.text
                DownloadManager.downloadVideoAndCreateAsset(videoLink: self.videoURL, title: title!, description: desct!, customItemID: self.customPodcastItem!.identifier)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @objc func handleCancel() {
        player.pause()
        dismiss(animated: true) {
        }
    }
    
    //MARK: - Player
    
    func startPlaying() {
        player.play()
        player?.addObserver(self, forKeyPath: Constants.kLoadedTimeRanges, options: .new, context: nil)
        
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
        if keyPath == Constants.kLoadedTimeRanges {
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
        controlsContainerView.frame = self.view.bounds
        self.view.addSubview(controlsContainerView)
        
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
        setUpControls(isHidden: true)
        stop()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if pausePlayButton.isHidden == true {
            setUpControls(isHidden: false)
            startTimer()
        } else {
            setUpControls(isHidden: true)
        }
    }
    
    func setUpControls(isHidden: Bool) {
        pausePlayButton.isHidden = isHidden
        videoSlider.isHidden = isHidden
        currentTimeLable.isHidden = isHidden
        videoLenghtLable.isHidden = isHidden
        cancelVideoButton.isHidden = isHidden
        saveVideoButton.isHidden = isHidden
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
