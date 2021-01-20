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
    let recordManager = RecordManager()
    
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
    
    let backViewLayer3: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    var backLayer3: AVCaptureVideoPreviewLayer?
    
    //MARK: -  viewDidload
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        }
        frontViewLayer.backgroundColor = .gray
        frontViewLayer.translatesAutoresizingMaskIntoConstraints = false
        frontViewLayer.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        frontViewLayer.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        frontViewLayer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35).isActive = true
        frontViewLayer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
        
        if !view.subviews.contains(backViewLayer1) {
            view.addSubview(backViewLayer1)
        }
        backViewLayer1.backgroundColor = .gray
        backViewLayer1.translatesAutoresizingMaskIntoConstraints = false
        backViewLayer1.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        backViewLayer1.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        backViewLayer1.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35).isActive = true
        backViewLayer1.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
        
        if !view.subviews.contains(backViewLayer2) {
            view.addSubview(backViewLayer2)
        }
        backViewLayer2.backgroundColor = .gray
        backViewLayer2.translatesAutoresizingMaskIntoConstraints = false
        backViewLayer2.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        backViewLayer2.topAnchor.constraint(equalTo: frontViewLayer.bottomAnchor, constant: 10).isActive = true
        backViewLayer2.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35).isActive = true
        backViewLayer2.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
        
        if !view.subviews.contains(backViewLayer3) {
            view.addSubview(backViewLayer3)
        }
        backViewLayer3.backgroundColor = .gray
        backViewLayer3.translatesAutoresizingMaskIntoConstraints = false
        backViewLayer3.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        backViewLayer3.topAnchor.constraint(equalTo: backViewLayer1.bottomAnchor, constant: 10).isActive = true
        backViewLayer3.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35).isActive = true
        backViewLayer3.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45).isActive = true
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
            recordManager.handleSingleTap()
            sender.setTitle("End Recording", for: .normal)
        }else {
            recordManager.handleDoubleTap()
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
        backLayer3 = backViewLayer3.videoPreviewLayer
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
            
//            guard self.camManager.setUpCamera(type: .builtInWideAngleCamera, position: .back, outputViewlayer: self.backLayer1!) else{
//                DispatchQueue.main.async {
//                    let alertController = UIAlertController(title: "Error", message: "issue while setuping back camera", preferredStyle: .alert)
//                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
//                    self.present(alertController, animated: true, completion: nil)
//                }
//                return
//            }
            
            guard self.camManager.setUpCamera(type: .builtInTelephotoCamera, position: .back, outputViewlayer: self.backLayer2!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "3rd camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            
            guard self.camManager.setUpCamera(type: .builtInTrueDepthCamera, position: .back, outputViewlayer: self.backLayer3!) else{
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: "4th camera", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK",style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
        }
    }
}

