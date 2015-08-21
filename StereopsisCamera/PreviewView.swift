//
//  PreviewView.swift
//  StereopsisCamera
//
//  Created by Koji Murata on 2015/08/21.
//  Copyright (c) 2015年 Koji Murata. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    private var previewLayer = AVCaptureVideoPreviewLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.addSublayer(previewLayer)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }

    override func layoutSublayersOfLayer(layer: CALayer!) {
        super.layoutSublayersOfLayer(layer)
        previewLayer.frame = bounds
    }
    
    var capturingRect: CGRect {
        get { return previewLayer.metadataOutputRectOfInterestForRect(previewLayer.bounds) }
    }
    
    var orientation: AVCaptureVideoOrientation {
        get { return previewLayer.connection.videoOrientation }
        set { previewLayer.connection.videoOrientation = newValue }
    }
    
    var session: AVCaptureSession! {
        get { return previewLayer.session }
        set { previewLayer.session = newValue }
    }
}
