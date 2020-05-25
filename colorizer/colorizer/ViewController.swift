//
//  ViewController.swift
//  colorizer
//
//  Created by Максим Ефимов on 25.05.2020.
//  Copyright © 2020 Максим Ефимов. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var promoImage: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        startButton.layer.masksToBounds = true
        startButton.layer.cornerRadius = 6
        picker.sourceType = .photoLibrary
        picker.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @IBAction func onStart(_ sender: UIButton) {
        self.present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        let grayscaleImage = convertImageToGrayScale(image: image)
        let model = try! VNCoreMLModel(for: colorizer().model)
        let request = VNCoreMLRequest(model: model) { (request, error) in
            self.processResult(for: request, error: error)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: grayscaleImage.cgImage!)
            do {
                try handler.perform([request])
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func processResult(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                print("error")
                return
            }
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let res = results as! [VNCoreMLFeatureValueObservation]
            
            let arr = res[0].featureValue.multiArrayValue!
            print(arr)
            self.promoImage.image = arr.image(min:-1, max:1)
        }
    }
}


func convertImageToGrayScale(image: UIImage) -> UIImage {
    // Create image rectangle with current image width/height
    let imageRect: CGRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    
    // Grayscale color space
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
    // Create bitmap content with current image size and grayscale colorspace
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
    let context = CGContext(data: nil, width: Int(UInt(image.size.width)), height: Int(UInt(image.size.height)), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
    
    // Draw image into current context, with specified rectangle using previously defined context (with grayscale colorspace)
    context?.draw(image.cgImage!, in: imageRect)
    
    // Create bitmap image info from pixel data in current context
    let imageRef: CGImage = context!.makeImage()!
    
    // Create a new UIImage object
    let newImage: UIImage = UIImage(cgImage: imageRef)
    
    // Return the new grayscale image
    return newImage
}

