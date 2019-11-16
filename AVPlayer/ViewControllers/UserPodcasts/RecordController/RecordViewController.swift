//
//  RecordViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 11/1/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {

    @IBOutlet weak var recordButton: UIButton!
    
    let captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    var videoFileOutput:AVCaptureMovieFileOutput?
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    
    var isRecording = false
    var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomInGestureRecognizer = UISwipeGestureRecognizer()
    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSessions()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
        recordButton.layer.cornerRadius = recordButton.frame.width / 2
        
        toggleCameraGestureRecognizer.direction = .up
        toggleCameraGestureRecognizer.addTarget(self, action: #selector(self.switchCamera))
        view.addGestureRecognizer(toggleCameraGestureRecognizer)
        
        zoomInGestureRecognizer.direction = .right
        zoomInGestureRecognizer.addTarget(self, action: #selector(zoomIn))
        view.addGestureRecognizer(zoomInGestureRecognizer)
        
        zoomOutGestureRecognizer.direction = .left
        zoomOutGestureRecognizer.addTarget(self, action: #selector(zoomOut))
        view.addGestureRecognizer(zoomOutGestureRecognizer)
    }
    
    func setupSessions() {
        captureSession.sessionPreset = AVCaptureSession.Preset.high
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentDevice = backCamera
    }
    
    func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            videoFileOutput = AVCaptureMovieFileOutput()
            captureSession.addOutput(videoFileOutput!)
            
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            } else {
                print("cant add audio input")
            }
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    func startRunningCaptureSession() {
        captureSession.startRunning()
    }
    
    // MARK: - Action methods

    @IBAction func cancelCamera(_ sender: Any) {
        dismiss(animated: true) {
        }
    }

    var customPodcastItem: PodcastItem?
    
    @IBAction func capture(_ sender: Any) {
    
        if !isRecording {
            isRecording = true
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: { () -> Void in
                self.recordButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            }, completion: nil)
            
            customPodcastItem = PodcastItem(identifier: UUID(), itemTitle: "", itemDescription: "", itemPubDate: "", itemDuration: "", itemURL: "", itemImage: "", itemAuthor: "", itemIsDownloaded: false, itemIsDeleted: false, itemMediaType: MediaType.customType, itemProgressStatus: ProgressStatus.new)

            let outputPath = NSTemporaryDirectory() + (customPodcastItem?.identifier.uuidString)! + ".mov"
            let outputFileURL = URL(fileURLWithPath: outputPath)
            print("outputPath = \(outputFileURL)")
            videoFileOutput?.startRecording(to: outputFileURL, recordingDelegate: self)
        } else {
            isRecording = false
            
            UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: { () -> Void in
                self.recordButton.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: nil)
            recordButton.layer.removeAllAnimations()
            videoFileOutput?.stopRecording()
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate methods
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error != nil {
            print("error fileOutput")
            return
        }
        performSegue(withIdentifier: "playVideo", sender: outputFileURL)
    }
    
    @objc func switchCamera() {
        captureSession.beginConfiguration()
        // Change the device based on the current camera
        let newDevice = (currentDevice?.position == AVCaptureDevice.Position.back) ? frontCamera : backCamera
        // Remove all inputs from the session
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        // Change to the new input
        let cameraInput:AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    @objc func zoomIn() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor < 5.0 {
                let newZoomFactor = min(zoomFactor + 1.0, 5.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    @objc func zoomOut() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor > 1.0 {
                let newZoomFactor = max(zoomFactor - 1.0, 1.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playVideo" {
            let destinationVC: CaptureVideoViewController = segue.destination as! CaptureVideoViewController
            let videoFileURL = sender as! URL
            destinationVC.videoURL = videoFileURL.absoluteString
            destinationVC.customPodcastItem = customPodcastItem
            print("")
        }
    }
}
