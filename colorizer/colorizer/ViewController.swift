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
    let model = try! VNCoreMLModel(for: Colorizer2().model)
    var originalImage: UIImage? = nil
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage else {
                fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
            }
            self.originalImage = image
            self.process(image)
        }
    }
    
    func process(_ image: UIImage) {
        activityIndicator.startAnimating()
        startButton.setTitle("", for: .normal)
        startButton.isEnabled = false
        let request = VNCoreMLRequest(model: model) { (request, error) in
            self.processResult(for: request, error: error)
        }
        request.imageCropAndScaleOption = .scaleFit
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: image.cgImage!)
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func processResult(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            
            guard let results = request.results as? [VNPixelBufferObservation] else {
                print("error", error ?? "")
                return
            }
            print(results[0].pixelBuffer)
            let ciImage = CIImage(cvPixelBuffer: results[0].pixelBuffer)
            let cgImage = self.convertCIImageToCGImage(inputImage: ciImage)!
            var uiImage = UIImage(cgImage: cgImage)
            let scale = uiImage.size.height / max(self.originalImage!.size.height,self.originalImage!.size.width)
            uiImage = self.cropToBounds(image: uiImage, width: self.originalImage!.size.width * scale, height: self.originalImage!.size.height * scale)
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "SaveViewController") as! SaveViewController
            newViewController.image = uiImage
            
            self.show(newViewController, sender: self)
            
            self.activityIndicator.stopAnimating()
            self.startButton.setTitle("Let's start", for: .normal)
            self.startButton.isEnabled = true
        }
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
    
    func cropToBounds(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
        
        let cgimage = image.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        let posX = (contextSize.width - width) / 2
        let posY = (contextSize.height - height) / 2
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: width, height: height)
        
        let imageRef: CGImage = cgimage.cropping(to: rect)!
        
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
}
