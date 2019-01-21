//
//  PhotoPickerManager.swift
//  DiaryApp
//
//  Created by Jun Kakeno on 1/15/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol PhotoPickerManagerDelegate: class {
    func manager(_ manager: PhotoPickerManager, didPickImage image: UIImage)
}

class PhotoPickerManager: NSObject {
    private let imagePickerController = UIImagePickerController()
    private let presentingController: UIViewController
    //Create a delegate property. 
    weak var delegate: PhotoPickerManagerDelegate?
    
    init(presentingViewController: UIViewController) {
        self.presentingController = presentingViewController
        super.init()
        
        configure()
    }
    
    //Helper to present the photo picker.
    func presentPhotoPicker(animated: Bool) {
        presentingController.present(imagePickerController, animated: animated, completion: nil)
    }
    
    //Helper to dismiss the photo picker.
    func dismissPhotoPicker(animated: Bool, completion: (() -> Void)?) {
        imagePickerController.dismiss(animated: animated, completion: completion)
    }
    
    //Photo picker configuration
    private func configure() {
        //If the camera is available use the camera else use the photo library
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.cameraDevice = .front
        } else {
            imagePickerController.sourceType = .photoLibrary
        }
        
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        
        //Make this class implement the method to exit the photo picker. That method is in UIImagePickerController's delegate property. Self can be assigned to this class delegate property because of the extension below it adopts the same delegate protocols as UIImagePickerController's delegate property.
        imagePickerController.delegate = self
    }
}

//Make this class adopt UIImagePickerControllerDelegate, UINavigationControllerDelegate to implement the method to exit the photo picker.
extension PhotoPickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //Method to conform to the delegate adopted. Method to exit the photo picker.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        print("Image taken")
        //Call the protocol method and pass the image taken with the camera.
        delegate?.manager(self, didPickImage: image)
    }
}























