//
//  AudioPlayerViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/31/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit
import AVFoundation

class AudioPlayerViewController: UIViewController {
    
    var player: AVPlayer!
    var audioURL: String = ""
    var podcstPlayerImage: UIImage!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var videoSlider: UISlider!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var podcastImage: UIImageView!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalLenghtLabel: UILabel!
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.startAnimating()
        return aiv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        podcastImage.image = podcstPlayerImage
        podcastImage.layer.cornerRadius = 30
        podcastImage.clipsToBounds = true
        setUpPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if audioURL.first == "f" {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPlaying()
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
            self.currentTimeLabel.text = "\(totalSeconds)"
            
            if let duration = self.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                self.videoSlider.value = Float(seconds / durationSeconds)
            }
        })
    }
    
    var counter = 0
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem.loadedTimeRanges" {
            activityIndicator.stopAnimating()
            if let duration = player?.currentItem?.duration {
                let time = CMTime()
                let totalSeconds = time.durationTexForTime(time: duration)
                totalLenghtLabel.text = "\(totalSeconds)"
            }
        }
    }
    
    func setUpPlayer() {
        let url = URL(string: audioURL)!
        player = AVPlayer(url: url)
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            
        }
    }
    
    var isPlaying = false
    
    @IBAction func playAction(_ sender: UIButton) {
        sender.pulsate()
        player.play()
    }

    @IBAction func restartAction(_ sender: UIButton) {
        sender.pulsate()
        if ((player.error == nil)) {
            player.seek(to: kCMTimeZero)
            player.play()
        }
    }

    @IBAction func pauseAction(_ sender: UIButton) {
        sender.pulsate()
        player?.pause()
    }

    @IBAction func closePlayerAction(_ sender: UIButton) {
        sender.pulsate()
        player.pause()
        dismiss(animated: true) {
        }
    }
    
    @IBAction func handleSliderChanged(_ sender: Any) {
        if let duration = player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(videoSlider.value) * totalSeconds
            
            let seekTime = CMTime(value: Int64(value), timescale: 1)
            player?.seek(to: seekTime, completionHandler: { (completedSeek) in
            })
        }
    }
}
