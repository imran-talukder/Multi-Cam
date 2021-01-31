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
    func finalOutput(fromVideoAt videoURL: URL, onComplete: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: videoURL)
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
              
              if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
                    let compositionAudioTrack = composition.addMutableTrack(
                      withMediaType: .audio,
                      preferredTrackID: kCMPersistentTrackID_Invalid) {
                    try compositionAudioTrack.insertTimeRange(
                      timeRange,
                      of: audioAssetTrack,
                      at: .zero)
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
        videoLayer.frame = CGRect(x: 40, y: 40, width: videoSize.width-80, height: videoSize.height-80)
        
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
          let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
          let transform = assetTrack.preferredTransform
          
          instruction.setTransform(transform, at: .zero)
          
          return instruction
    }
}

