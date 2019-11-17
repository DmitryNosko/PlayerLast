//
//  CMTimeExtension.swift
//  AVPlayer
//
//  Created by USER on 11/17/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import AVFoundation

extension CMTime {
    
    func durationTexForTime(time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
