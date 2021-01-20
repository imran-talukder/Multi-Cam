//
//  ViewController.swift
//  Multi_Cam_App
//
//  Created by Appnap WS01 on 20/1/21.
//

import UIKit

class ViewController: UIViewController {

    
    //MARK: -  Properties

    
    let frontViewLayer: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    
    let backViewLayer1: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    
    let backViewLayer2: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    
    let backViewLayer3: ViewForCamera = {
        let view = ViewForCamera()
        view.backgroundColor = .clear
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addCameraViews()
        addActionButtons()
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
        
    }

}

