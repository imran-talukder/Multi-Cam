//
//  ViewForCamera.swift
//  Multi_Cam_App
//
//  Created by Appnap WS01 on 20/1/21.
//

import UIKit
import AVFoundation

class ViewForCamera: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        layer.videoGravity = .resizeAspectFill
        return layer
    }
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
