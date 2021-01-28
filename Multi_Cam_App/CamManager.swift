//
//  CamManager.swift
//  Multi_Cam_App
//
//  Created by Appnap WS01 on 20/1/21.
//

import Foundation
import AVFoundation
import UIKit
import Photos

class  CamManager: NSObject {
    var movieRecorder: MovieRecorder?
    var movieRecorder2: MovieRecorder?
    var backgroundRecordingID: UIBackgroundTaskIdentifier?
    var videoDataOutput = AVCaptureVideoDataOutput()
    var dualVideoSession = AVCaptureMultiCamSession()
    
    var audioDeviceInput: AVCaptureDeviceInput?
    var backAudioDataOutput = AVCaptureAudioDataOutput()
    var frontAudioDataOutput = AVCaptureAudioDataOutput()

    let dualVideoSessionQueue = DispatchQueue(label: "dual video session queue")
    let dualVideoSessionOutputQueue = DispatchQueue(label: "dual video session data output queue")
    var delegate: CamManagerToMainVC?
    //MARK: - Buffer converting
    var videoTrackSourceFormatDescription: CMFormatDescription?
    var currentPiPSampleBuffer: CMSampleBuffer?
    
    
    weak var viewController: UIViewController!
    func saveMovieToPhotoLibrary(_ movieURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Save the movie file to the photo library and clean up.
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: movieURL, options: options)
                }, completionHandler: { success, error in
                    if !success {
                        print("\(Bundle.main.applicationName) couldn't save the movie to your photo library: \(String(describing: error))")
                    } else {
                        // Clean up
                        if FileManager.default.fileExists(atPath: movieURL.path) {
                            do {
                                try FileManager.default.removeItem(atPath: movieURL.path)
                            } catch {
                                print("Could not remove file at url: \(movieURL)")
                            }
                        }
                        
                        if let currentBackgroundRecordingID = self.backgroundRecordingID {
                            self.backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                            
                            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                            }
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    let alertMessage = "Alert message when the user has not authorized photo library access"
                    let message = NSLocalizedString("\(Bundle.main.applicationName) does not have permission to access the photo library", comment: alertMessage)
                    let alertController = UIAlertController(title: Bundle.main.applicationName, message: message, preferredStyle: .alert)
                    self.viewController.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func configureDualVideo(viewController: UIViewController,block: @escaping () -> Void){
        self.viewController = viewController
        addNotifer()
        dualVideoSessionQueue.async {
            self.setUpSession(block: block)
        }
      }
    

    func setUpSession(block: () -> Void){
        if !AVCaptureMultiCamSession.isMultiCamSupported{
            DispatchQueue.main.async {
               let alertController = UIAlertController(title: "Error", message: "Device is not supporting multicam feature", preferredStyle: .alert)
               alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                self.viewController.present(alertController, animated: true, completion: nil)
            }
            return
        }
            
        block()
        
        start()
    }
    
    func createAudioSettings() -> [String: NSObject]? {
        guard let backMicrophoneAudioSettings = backAudioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else {
            print("Could not get back microphone audio settings")
            return nil
        }
//        guard let frontMicrophoneAudioSettings = frontAudioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else {
//            print("Could not get front microphone audio settings")
//            return nil
//        }
        
            // The front and back microphone audio settings are equal, so return either one
        return backMicrophoneAudioSettings
        
    }
    
    func createVideoSettings() -> [String: NSObject]? {
        guard let backCameraVideoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else {
            print("Could not get back camera video settings")
            return nil
        }
        guard let frontCameraVideoSettings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject] else {
            print("Could not get front camera video settings")
            return nil
        }
        
        if backCameraVideoSettings == frontCameraVideoSettings {
            // The front and back camera video settings are equal, so return either one
            return backCameraVideoSettings
        } else {
            print("Front and back camera video settings are not equal. Check your AVCaptureVideoDataOutput configuration.")
            return nil
        }
    }
    func createVideoTransform() -> CGAffineTransform? {
        guard let backCameraVideoConnection = videoDataOutput.connection(with: .video) else {
                print("Could not find the back and front camera video connections")
                return nil
        }
        
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
        
        // Compute transforms from the back camera's video orientation to the device's orientation
        let backCameraTransform = backCameraVideoConnection.videoOrientationTransform(relativeTo: videoOrientation)

        return backCameraTransform

    }
    
    
    
    func setUpCamera(type: AVCaptureDevice.DeviceType,position: AVCaptureDevice.Position, outputViewlayer: AVCaptureVideoPreviewLayer) -> Bool{
        
        outputViewlayer.setSessionWithNoConnection(dualVideoSession)

        //start configuring dual video session
        dualVideoSession.beginConfiguration()
            defer {
                //save configuration setting
                dualVideoSession.commitConfiguration()
            }
                
            //search back camera
            guard let backCamera = AVCaptureDevice.default(type, for: .video, position: position) else {
                print("no back camera")
                return false
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()

            let deviceInput: AVCaptureDeviceInput?
            // append back camera input to dual video session
            do {
                deviceInput = try AVCaptureDeviceInput(device: backCamera)
                
                guard let deviceInput = deviceInput, dualVideoSession.canAddInput(deviceInput) else {
                    print("no back camera device input")
                    return false
                }
                dualVideoSession.addInputWithNoConnections(deviceInput)
            } catch {
                print("no back camera device input: \(error)")
                return false
            }
            
            // seach back video port
            guard let backVideoPort = deviceInput?.ports(for: .video, sourceDeviceType: backCamera.deviceType, sourceDevicePosition: backCamera.position).first else {
                print("no back camera input's video port")
                return false
            }
            
            // append back video ouput
            guard dualVideoSession.canAddOutput(videoDataOutput) else {
                print("no back camera output")
                return false
            }
            dualVideoSession.addOutputWithNoConnections(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
            
            // connect back ouput to dual video connection
            let backOutputConnection = AVCaptureConnection(inputPorts: [backVideoPort], output: videoDataOutput)
            guard dualVideoSession.canAddConnection(backOutputConnection) else {
                print("no connection to the back camera video data output")
                return false
            }
            dualVideoSession.addConnection(backOutputConnection)
            backOutputConnection.videoOrientation = .portrait

            // connect back input to back layer
        
            let backConnection = AVCaptureConnection(inputPort: backVideoPort, videoPreviewLayer: outputViewlayer)
            guard dualVideoSession.canAddConnection(backConnection) else {
                print("no a connection to the back camera video preview layer")
                return false
            }
            dualVideoSession.addConnection(backConnection)
        
        return true
    }
    
    func setUpAudio() -> Bool{
         //start configuring dual video session
        dualVideoSession.beginConfiguration()
        defer {
            //save configuration setting
            dualVideoSession.commitConfiguration()
        }
        
        // serach audio device for dual video session
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("no the microphone")
            return false
        }
        
        // append auido to dual video session
        do {
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            guard let audioInput = audioDeviceInput,
                dualVideoSession.canAddInput(audioInput) else {
                    print("no audio input")
                    return false
            }
            dualVideoSession.addInputWithNoConnections(audioInput)
        } catch {
            print("no audio input: \(error)")
            return false
        }
        
        //search audio port back
        guard let audioInputPort = audioDeviceInput,
            let backAudioPort = audioInputPort.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .back).first else {
            print("no front back port")
            return false
        }
        
        // search audio port front
//        guard let frontAudioPort = audioInputPort.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .front).first else {
//            print("no front audio port")
//            return false
//        }
        
        // append back output to dual video session
        guard dualVideoSession.canAddOutput(backAudioDataOutput) else {
            print("no back audio data output")
            return false
        }
        dualVideoSession.addOutputWithNoConnections(backAudioDataOutput)
        backAudioDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // append front ouput to dual video session
//        guard dualVideoSession.canAddOutput(frontAudioDataOutput) else {
//            print("no front audio data output")
//            return false
//        }
        //dualVideoSession.addOutputWithNoConnections(frontAudioDataOutput)
        //frontAudioDataOutput.setSampleBufferDelegate(self, queue: dualVideoSessionOutputQueue)
        
        // add back output to dual video session
        let backOutputConnection = AVCaptureConnection(inputPorts: [backAudioPort], output: backAudioDataOutput)
        guard dualVideoSession.canAddConnection(backOutputConnection) else {
            print("no back audio connection")
            return false
        }
        dualVideoSession.addConnection(backOutputConnection)
        
        // add front output to dual video session
//        let frontutputConnection = AVCaptureConnection(inputPorts: [frontAudioPort], output: frontAudioDataOutput)
//        guard dualVideoSession.canAddConnection(frontutputConnection) else {
//            print("no front audio connection")
//            return false
//        }
//        dualVideoSession.addConnection(frontutputConnection)
        
        return true
    }
    
    func start() {
        dualVideoSessionQueue.async {
            self.dualVideoSession.startRunning()
        }
    }
    
    //MARK:- Add and Handle Observers
    func addNotifer() {
        
        // A session can run only when the app is full screen. It will be interrupted in a multi-app layout.
        // Add observers to handle these session interruptions and inform the user.
                
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError,object: dualVideoSession)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: dualVideoSession)
        
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: .AVCaptureSessionInterruptionEnded, object: dualVideoSession)
    }
    
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
            
    }
        
    @objc func sessionInterruptionEnded(notification: NSNotification) {
        
    }
        
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        print("Capture session runtime error: \(error)")
        
        /*
        Automatically try to restart the session running if media services were
        reset and the last start running succeeded. Otherwise, enable the user
        to try to resume the session running.
        */
        if error.code == .mediaServicesWereReset {
            
        } else {
           
        }
    }
}


extension CamManager: AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate {

     //MARK:- AVCaptureOutput Delegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        
        let inputSourceInfo = "\(connection)"
        if inputSourceInfo.contains("Back Camera") {
            let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
            let image : UIImage = self.convert(cmage: ciimage)
            delegate?.getImage(image: image)

        }
        if movieRecorder?.isRecording == true {
            if output is AVCaptureAudioDataOutput {
                if let recorder = movieRecorder,
                    recorder.isRecording {
                    recorder.recordAudio(sampleBuffer: sampleBuffer)
                }
                if let recorder = movieRecorder2,
                    recorder.isRecording {
                    recorder.recordAudio(sampleBuffer: sampleBuffer)
                }
            }else if output is AVCaptureVideoDataOutput {
                if inputSourceInfo.contains("Back Camera") {
                    
                    if output is AVCaptureVideoDataOutput {
                        if let recorder = movieRecorder {
                            recorder.recordVideo(sampleBuffer: sampleBuffer)
                        }
                    }
                }
                else if inputSourceInfo.contains("Front Camera") {
                    if output is AVCaptureVideoDataOutput {
                        if let recorder = movieRecorder2 {
                            recorder.recordVideo(sampleBuffer: sampleBuffer)
                        }
                    }
                }
            }
        }
    }
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage, scale: 5.0, orientation: .init(UIImage.Orientation(rawValue: 0)!)!)
        return image
    }
}


protocol CamManagerToMainVC {
    func getImage(image: UIImage)
}
