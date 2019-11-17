//
//  VideoViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/30/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPlayerViewController: UIViewController {
    
    private struct Constants {
        static let kPauseImage = "pause"
        static let kDefaultLenghtValue = "00:00"
        static let kVolumeImage = "volume"
        static let kCancelImage = "cancel"
        static let kPlayImage = "play"
        static let kLoadedTimeRanges = "currentItem.loadedTimeRanges"
        static let kEmptyString = ""
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet weak var videoView: UIView!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: String = Constants.kEmptyString
    
    let controlsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.startAnimating()
        return aiv
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
    
    let videoDurationSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = UIColor.red
        slider.maximumTrackTintColor = UIColor.white
        slider.addTarget(self, action: #selector(handleDurationSliderChange), for: .valueChanged)
        return slider
    }()
    
    let volumeSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.maximumValueImage = UIImage(named: Constants.kVolumeImage)
        slider.minimumTrackTintColor = UIColor.red
        slider.maximumTrackTintColor = UIColor.white
        slider.addTarget(self, action: #selector(handleVolumeSliderChange), for: .valueChanged)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpPlayerView(url: videoURL)
        configerateControlsContainerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPlaying()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
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
    
    @objc func handleDurationSliderChange() {
        if let duration = player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(videoDurationSlider.value) * totalSeconds
            
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }
    
    @objc func handleVolumeSliderChange() {
        player?.volume = volumeSlider.value
    }
    
    @objc func handleCancel() {
        player.pause()
        dismiss(animated: true) {
        }
    }
    
    //MARK: - Player setUp's
    
    func startPlaying() {
        player.play()
        volumeSlider.value = player.volume
        player?.addObserver(self, forKeyPath: Constants.kLoadedTimeRanges, options: .new, context: nil)
        
        let interval = CMTime(value: 1, timescale: 2)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (progressTime) in
            
            let time = CMTime()
            let seconds = CMTimeGetSeconds(progressTime)
            let totalSeconds = time.durationTexForTime(time: progressTime)
            self.currentTimeLable.text = "\(totalSeconds)"
            
            if let duration = self.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                self.videoDurationSlider.value = Float(seconds / durationSeconds)
            }
        })
    }
    
    var counter = 0
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == Constants.kLoadedTimeRanges {
            activityIndicatorView.stopAnimating()
            controlsContainerView.backgroundColor = UIColor.clear
            if counter == 0 {
                pausePlayButton.isHidden = true
                videoDurationSlider.isHidden = true
                currentTimeLable.isHidden = true
                videoLenghtLable.isHidden = true
                cancelVideoButton.isHidden = true
                volumeSlider.isHidden = true
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
    
    func configerateControlsContainerView() {
        controlsContainerView.frame = self.view.bounds
        self.view.addSubview(controlsContainerView)
        
        if videoURL.first != "f" {
            controlsContainerView.addSubview(activityIndicatorView)
            setUpActivityIndicatorConstraints()
        }
        controlsContainerView.addSubview(pausePlayButton)
        controlsContainerView.addSubview(videoLenghtLable)
        controlsContainerView.addSubview(videoDurationSlider)
        controlsContainerView.addSubview(currentTimeLable)
        controlsContainerView.addSubview(cancelVideoButton)
        controlsContainerView.addSubview(volumeSlider)
        
        setUpPauseButtonContraints()
        setUpVideoLenghtLabelConstraints()
        setUpVideoSliderConstraints()
        setUpCurrentTimeLableConstraints()
        setCancelVideoButtonContraints()
        setUpVolumeSliderConstraints()
    }
    
    private func setUpPlayerView(url: String) {
        if let url = NSURL(string: url) {
            player = AVPlayer(url: url as URL)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resize
            videoView.layer.addSublayer(playerLayer)
        }
    }
    
    //MARK: - Touches
    
    var timer: Timer?
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5,
                                     target: self,
                                     selector: #selector(hideAllButtons),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    func stop(){
        if(timer != nil){timer!.invalidate()}
    }
    
    @objc func hideAllButtons() {
        isHiddenControls(value: true)
        stop()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if pausePlayButton.isHidden == true {
            isHiddenControls(value: false)
            startTimer()
        } else {
            isHiddenControls(value: true)
        }
    }
    
    func isHiddenControls(value: Bool) {
        pausePlayButton.isHidden = value
        videoDurationSlider.isHidden = value
        currentTimeLable.isHidden = value
        videoLenghtLable.isHidden = value
        cancelVideoButton.isHidden = value
        volumeSlider.isHidden = value
    }
    
    //MARK: Constraints
    
    private func setUpActivityIndicatorConstraints() {
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
    private func setUpPauseButtonContraints() {
        pausePlayButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        pausePlayButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        pausePlayButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        pausePlayButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setUpVideoLenghtLabelConstraints() {
        videoLenghtLable.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
        videoLenghtLable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        videoLenghtLable.widthAnchor.constraint(equalToConstant: 50).isActive = true
        videoLenghtLable.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }
    
    private func setUpVideoSliderConstraints() {
        videoDurationSlider.rightAnchor.constraint(equalTo: videoLenghtLable.safeAreaLayoutGuide.leftAnchor, constant: -8).isActive = true
        videoDurationSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        videoDurationSlider.leftAnchor.constraint(equalTo: currentTimeLable.safeAreaLayoutGuide.rightAnchor, constant: 8).isActive = true
        videoDurationSlider.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    private func setUpCurrentTimeLableConstraints() {
        currentTimeLable.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8).isActive = true
        currentTimeLable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        currentTimeLable.widthAnchor.constraint(equalToConstant: 50).isActive = true
        currentTimeLable.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }
    
    private func setCancelVideoButtonContraints() {
        cancelVideoButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
        cancelVideoButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        cancelVideoButton.widthAnchor.constraint(equalToConstant: 65).isActive = true
        cancelVideoButton.heightAnchor.constraint(equalToConstant: 65).isActive = true
    }
    
    private func setUpVolumeSliderConstraints() {
        volumeSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 28).isActive = true
        volumeSlider.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22).isActive = true
        volumeSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
    }
}

