//
//  ViewController.swift
//  Multi_Cam_App
//
//  Created by Appnap WS01 on 20/1/21.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    
    //MARK: -  Properties
    
    let camManager = CamManager()
    
    let frontViewLayer: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    var frontLayer: AVCaptureVideoPreviewLayer?
    
    let backViewLayer1: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    var backLayer1: AVCaptureVideoPreviewLayer?
    
    let backViewLayer2: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    var backLayer2: AVCaptureVideoPreviewLayer?
    
    let backViewLayer3: UIImageView = {
        let view = UIImageView()
        return view
    }()
    var backLayer3: UIImageView?
    
    //MARK: -  viewDidload
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camManager.delegate = self
        addCameraViews()
        addActionButtons()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if targetEnvironment(simulator)
          let alertController = UIAlertController(title: "Multi Cam-App", message: "Please run on physical device", preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
          self.present(alertController, animated: true, completion: nil)
          return
        #endif
    }
    
    let startEndtButton: UIButton = UIButton()
    private func addCameraViews() {
        if !view.subviews.contains(frontViewLayer) {
            view.addSubview(frontViewLayer)
            frontViewLayer.backgroundColor = .gray
            frontViewLayer.translatesAutoresizingMaskIntoConstraints = false
            frontViewLayer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
            frontViewLayer.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
            frontViewLayer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4).isActive = true
            frontViewLayer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
        }
        
        if !view.subviews.contains(backViewLayer1) {
            view.addSubview(backViewLayer1)
            backViewLayer1.backgroundColor = .gray
            backViewLayer1.translatesAutoresizingMaskIntoConstraints = false
            backViewLayer1.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
            backViewLayer1.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
            backViewLayer1.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4).isActive = true
            backViewLayer1.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
        }
        
        if !view.subviews.contains(backViewLayer2) {
            view.addSubview(backViewLayer2)
            backViewLayer2.backgroundColor = .gray
            backViewLayer2.translatesAutoresizingMaskIntoConstraints = false
            backViewLayer2.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
            backViewLayer2.topAnchor.constraint(equalTo: frontViewLayer.bottomAnchor, constant: 10).isActive = true
            backViewLayer2.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4).isActive = true
            backViewLayer2.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
        }
        
        if !view.subviews.contains(backViewLayer3) {
            view.addSubview(backViewLayer3)
            backViewLayer3.backgroundColor = .gray
            backViewLayer3.translatesAutoresizingMaskIntoConstraints = false
            backViewLayer3.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
            backViewLayer3.topAnchor.constraint(equalTo: backViewLayer1.bottomAnchor, constant: 10).isActive = true
            backViewLayer3.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4).isActive = true
            backViewLayer3.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
        }
        
    }
    
    private func addActionButtons() {
        if !view.subviews.contains(startEndtButton) {
            view.addSubview(startEndtButton)
            startEndtButton.layer.cornerRadius = 10
            startEndtButton.backgroundColor = .red
            startEndtButton.setTitle("Start", for: .normal)
            startEndtButton.setTitleColor(.green, for: .highlighted)
            startEndtButton.translatesAutoresizingMaskIntoConstraints = false
            startEndtButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            startEndtButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7).isActive = true
            startEndtButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
            startEndtButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            startEndtButton.addTarget(self, action: #selector(recordButtonTrigered(_:)), for: .touchUpInside)
        }
    }
    @objc func recordButtonTrigered(_ sender: UIButton) {
        if sender.titleLabel?.text == "Start" {
            camManager.movieRecorder?.isRecording = true
            camManager.movieRecorder2?.isRecording = true
            guard let audioSettings = camManager.createAudioSettings() else {
                print("Could not create audio settings")
                return
            }
            
            guard let videoSettings = camManager.createVideoSettings() else {
                print("Could not create video settings")
                return
            }
            
            guard let videoTransform = camManager.createVideoTransform() else {
                print("Could not create video transform")
                return
            }

            camManager.movieRecorder = MovieRecorder(audioSettings: audioSettings,
                                               videoSettings: videoSettings,
                                               videoTransform: videoTransform)
            
            
            camManager.movieRecorder?.startRecording()
            
            camManager.movieRecorder2 = MovieRecorder(audioSettings: audioSettings,
                                               videoSettings: videoSettings,
                                               videoTransform: videoTransform)
            
            
            camManager.movieRecorder2?.startRecording()
            sender.setTitle("End Recording", for: .normal)
        }else {
            camManager.movieRecorder?.isRecording = false
            camManager.movieRecorder?.stopRecording { movieURL in
                self.camManager.saveMovieToPhotoLibrary(movieURL)
            }
            camManager.movieRecorder2?.isRecording = false
            camManager.movieRecorder2?.stopRecording { movieURL in
                self.camManager.saveMovieToPhotoLibrary(movieURL)
            }
            let alertController = UIAlertController(title: "Saved!", message: "Video saved to your gallery.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Done",style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            sender.setTitle("Start", for: .normal)
        }
    }
}

extension ViewController {
    func setup() {
        
        #if targetEnvironment(simulator)
            return
        #endif
        
        frontLayer = frontViewLayer.videoPreviewLayer
        backLayer1 = backViewLayer1.videoPreviewLayer
        backLayer2 = backViewLayer2.videoPreviewLayer
        //backLayer3 = backViewLayer3.videoPreviewLayer
        dualVideoPermisson()
    }
    
    func dualVideoPermisson(){
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                // The user has previously granted access to the camera.
                configureDualVideo()
                break
                
            case .notDetermined:
                
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if granted{
                        self.configureDualVideo()
                    }
                })
                
                break
                
            default:
                // The user has previously denied access.
            DispatchQueue.main.async {
                let changePrivacySetting = "Device doesn't have permission to use the camera, please change privacy settings"
                let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "Settings", style: .`default`,handler: { _ in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL,  options: [:], completionHandler: nil)
                    }
                }))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func configureDualVideo() {
        if UIDevice.current.isMultitaskingSupported {
            camManager.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
        camManager.configureDualVideo(viewController: self) { [weak self] in
            guard let self = self else { return }
            
            guard self.camManager.setUpCamera(type: .builtInWideAngleCamera, position: .front, outputViewlayer: self.frontLayer!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "issue while setuping front camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            
            guard self.camManager.setUpCamera(type: .builtInWideAngleCamera, position: .back, outputViewlayer: self.backLayer1!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "issue while setuping back camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            
            guard self.camManager.setUpCamera(type: .builtInUltraWideCamera, position: .back, outputViewlayer: self.backLayer2!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "3rd camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
//            guard self.camManager.setUpCamera(type: .builtInUltraWideCamera, position: .back, outputViewlayer: self.backLayer3!) else{
//                DispatchQueue.main.async {
//                    let alertController = UIAlertController(title: "Error", message: "4th camera", preferredStyle: .alert)
//                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
//                    self.present(alertController, animated: true, completion: nil)
//                }
//                return
//            }
            guard self.camManager.setUpAudio() else {
                print("Audio Failed-----------------")
                return
            }
        }
    }
}

extension ViewController: CamManagerToMainVC {
    func getImage(image: UIImage) {
        DispatchQueue.main.async {
            self.backViewLayer3.image = image
        }
    }
}


extension Bundle {
    
    var applicationName: String {
        if let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return name
        } else if let name = object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        
        return "-"
    }
}


extension AVCaptureVideoOrientation {
    
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
    
    func angleOffsetFromPortraitOrientation(at position: AVCaptureDevice.Position) -> Double {
        switch self {
        case .portrait:
            return position == .front ? .pi : 0
        case .portraitUpsideDown:
            return position == .front ? 0 : .pi
        case .landscapeRight:
            return -.pi / 2.0
        case .landscapeLeft:
            return .pi / 2.0
        default:
            return 0
        }
    }
}

extension AVCaptureConnection {
    func videoOrientationTransform(relativeTo destinationVideoOrientation: AVCaptureVideoOrientation) -> CGAffineTransform {
        let videoDevice: AVCaptureDevice
        if let deviceInput = inputPorts.first?.input as? AVCaptureDeviceInput, deviceInput.device.hasMediaType(.video) {
            videoDevice = deviceInput.device
        } else {
            // Fatal error? Programmer error?
            print("Video data output's video connection does not have a video device")
            return .identity
        }
        
        let fromAngleOffset = videoOrientation.angleOffsetFromPortraitOrientation(at: videoDevice.position)
        let toAngleOffset = destinationVideoOrientation.angleOffsetFromPortraitOrientation(at: videoDevice.position)
        let angleOffset = CGFloat(toAngleOffset - fromAngleOffset)
        let transform = CGAffineTransform(rotationAngle: angleOffset)
        
        return transform
    }
}
