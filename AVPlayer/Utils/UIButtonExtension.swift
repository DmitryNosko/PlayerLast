//
//  UIButtonExtension.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 11/1/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func pulsate() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.2
        pulse.fromValue = 0.95
        pulse.toValue = 1
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 0.5
        pulse.damping = 1.0
        layer.add(pulse, forKey: nil)
    }
}
