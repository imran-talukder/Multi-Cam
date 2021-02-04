//
//  VideoEditor.swift
//  Multi_Cam_App
//
//  Created by Appnap WS01 on 28/1/21.
//

import AVFoundation
import UIKit
import Photos

class VideoEditor {
    func finalOutput(fromVideoAt videoURL: URL, audioURL: URL, onComplete: @escaping (URL?) -> Void) {
        
        let asset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        let composition = AVMutableComposition()
        
        guard
              let compositionTrack = composition.addMutableTrack(
                withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let assetTrack = asset.tracks(withMediaType: .video).first
              else {
                print("Something is wrong with the asset.")
                onComplete(nil)
                return
        }
        
        do {
              let timeRange = CMTimeRange(start: CMTimeMake(value: 1, timescale: Int32(7.13)), duration: asset.duration)
              try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
              
              if let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first,
                    let compositionAudioTrack = composition.addMutableTrack(
                      withMediaType: .audio,
                      preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try compositionAudioTrack.insertTimeRange(
                      timeRange,
                      of: audioAssetTrack,
                        at: CMTimeMake(value: 1, timescale: Int32(0.65)))
              }
        } catch {
              print(error)
              onComplete(nil)
              return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        
        let videoSize: CGSize
        if videoInfo.isPortrait {
                videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
        } else {
                videoSize = assetTrack.naturalSize
        }
        
        //FIXME:- layers
        let backgroundLayer = CALayer()
        backgroundLayer.frame = CGRect(origin: .zero, size: videoSize)
        backgroundLayer.backgroundColor = UIColor.green.cgColor
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        
        let videoLayer2 = CALayer()
        videoLayer2.frame = CGRect(origin: .zero, size: videoSize)
        //videoLayer2.backgroundColor = UIColor.red.cgColor
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
    
        
        
        
        
        //addImage(to: videoLayer2, image: UIImage(systemName: "sun.haze")!)
    
    
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(backgroundLayer)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(videoLayer2)
        outputLayer.addSublayer(overlayLayer)
    
    
    
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
         
    
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
    
    
    
    
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                print("Cannot create export session.")
                onComplete(nil)
                return
        }
    
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mov")
    
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
    
        export.exportAsynchronously {
              DispatchQueue.main.async {
                    switch export.status {
                        case .completed:
                              onComplete(exportURL)
                        default:
                              print("Something went wrong during export.")
                              print(export.error ?? "unknown error")
                              onComplete(nil)
                          break
                    }
              }
        }
    }
    private func addImage(to layer: CALayer, image: UIImage) {
        let imageLayer = CALayer()
        imageLayer.frame = CGRect(origin: .zero, size: layer.frame.size)
        imageLayer.contents = image.cgImage
        imageLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(imageLayer)
    }
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
          var assetOrientation = UIImage.Orientation.up
          var isPortrait = false
          if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
          } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
          } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
          } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
          }
          
          return (assetOrientation, isPortrait)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
//          let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
//          let transform = assetTrack.preferredTransform
//
//          instruction.setTransform(transform, at: .zero)
//
//          return instruction
        
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let orientationAspectTransform: CGAffineTransform
        let sourceVideoIsRotated: Bool = assetTrack.preferredTransform.a == 0
        if sourceVideoIsRotated {
          orientationAspectTransform = CGAffineTransform(scaleX: assetTrack.naturalSize.width/assetTrack.naturalSize.height,
                                                         y: assetTrack.naturalSize.height/assetTrack.naturalSize.width)
        } else {
          orientationAspectTransform = .identity
        }

        let bugFixTransform = CGAffineTransform(scaleX: 1080/assetTrack.naturalSize.width,
                                                y: 1920/assetTrack.naturalSize.height)
        
                
        let transform = assetTrack.preferredTransform.concatenating(bugFixTransform).concatenating(orientationAspectTransform)
        instruction.setTransform(transform, at: .zero)
        return instruction
      
        
    }
    
    func scaleAndPositionInAspectFillMode(forTrack track:AVAssetTrack, inArea area: CGSize) -> (scale: CGSize, position: CGPoint) {
        let assetSize = self.assetSize(forTrack: track)
        let aspectFillSize  = CGSize.aspectFill(videoSize: assetSize, boundingSize: area)
        let aspectFillScale = CGSize(width: aspectFillSize.width/assetSize.width, height: aspectFillSize.height/assetSize.height)
        let position = CGPoint(x: (area.width - aspectFillSize.width)/2.0, y: (area.height - aspectFillSize.height)/2.0)
        return (scale: aspectFillScale, position: position)
    }
    
    func assetSize(forTrack videoTrack:AVAssetTrack) -> CGSize {
        let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    
    
}


extension CGSize {
    
    static func aspectFit(videoSize: CGSize, boundingSize: CGSize) -> CGSize {
        
        var size = boundingSize
        let mW = boundingSize.width / videoSize.width;
        let mH = boundingSize.height / videoSize.height;
        
        if( mH < mW ) {
            size.width = boundingSize.height / videoSize.height * videoSize.width;
        }
        else if( mW < mH ) {
            size.height = boundingSize.width / videoSize.width * videoSize.height;
        }
        
        return size;
    }
    
    static func aspectFill(videoSize: CGSize, boundingSize: CGSize) -> CGSize {
        
        var size = boundingSize
        let mW = boundingSize.width / videoSize.width;
        let mH = boundingSize.height / videoSize.height;
        
        if( mH > mW ) {
            size.width = boundingSize.height / videoSize.height * videoSize.width;
        }
        else if ( mW > mH ) {
            size.height = boundingSize.width / videoSize.width * videoSize.height;
        }
        
        return size;
    }
}

