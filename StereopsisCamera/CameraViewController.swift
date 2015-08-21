//
//  CameraViewController.swift
//  StereopsisCamera
//
//  Created by Koji Murata on 2015/08/21.
//  Copyright (c) 2015年 Koji Murata. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    @IBOutlet weak var previewView: PreviewView! {
        didSet {
            previewView.session = session
        }
    }
    
    @IBOutlet weak var presentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var presentViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!

    private let sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
    private let session = AVCaptureSession()
    private lazy var videoDeviceInput: AVCaptureDeviceInput = {
        var error: NSError?

        let videoDevice = self.device(AVMediaTypeVideo, position: .Back)
        let videoDeviceInput = AVCaptureDeviceInput(device: videoDevice, error: &error)
        
        if let e = error {
            println(e)
        }
        
        return videoDeviceInput
    }()
    
    private var stillImageOutput: AVCaptureStillImageOutput!
    
    enum Eye {
        case Right
        case Left
    }
    
    private var previewEye = Eye.Right
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dispatch_async(sessionQueue) {
            if self.session.canAddInput(self.videoDeviceInput) {
                self.session.addInput(self.videoDeviceInput)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.previewView.orientation = AVCaptureVideoOrientation.LandscapeLeft
            }
            
            let stillImageOutput = AVCaptureStillImageOutput()
            if (self.session.canAddOutput(stillImageOutput)) {
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                self.session.addOutput(stillImageOutput)
                self.stillImageOutput = stillImageOutput
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        dispatch_async(sessionQueue) {
            self.session.startRunning()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        dispatch_async(sessionQueue) {
            self.session.stopRunning()
        }
    }
    
    private func device(mediaType: String, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType) as! [AVCaptureDevice]
        var captureDevice = devices.first
        
        for device in devices {
            if device.position == position {
                captureDevice = device
                break
            }
        }
        return captureDevice!
    }
    
    private func setFlashMode(flashMode: AVCaptureFlashMode, device: AVCaptureDevice) {
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            var error: NSError?
            if device.lockForConfiguration(&error) {
                device.flashMode = flashMode
                device.unlockForConfiguration()
            }
            if let e = error {
                println(e.localizedDescription)
            }
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        dispatch_async(sessionQueue) {
            self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation = self.previewView.orientation
            
            self.setFlashMode(.Auto, device: self.videoDeviceInput.device)

            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) {(imageDataSampleBuffer, error) in
                if imageDataSampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let image = UIImage(data:imageData)
                    dispatch_async(dispatch_get_main_queue()) {
                        switch self.previewEye {
                        case .Left:
                            self.presentViewTrailingConstraint.active = false
                            self.presentViewLeadingConstraint.active = true
                            self.rightImageView.image = image
                        case .Right:
                            self.presentViewLeadingConstraint.active = false
                            self.presentViewTrailingConstraint.active = true
                            self.leftImageView.image = image
                        }
                        self.previewEye = (self.previewEye == .Right ? .Left : .Right)
                    }
                }
            }
        }
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        previewView.orientation = AVCaptureVideoOrientation(rawValue: toInterfaceOrientation.rawValue)!
    }
}