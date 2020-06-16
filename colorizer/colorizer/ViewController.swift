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
    let model = try! VNCoreMLModel(for: Colorizer().model)
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var n: Int = 0
    var m: Int = 0
    
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
            let img = image
            self.process(img)
        }
    }
    
    func process(_ image: UIImage) {
        activityIndicator.startAnimating()
        startButton.setTitle("", for: .normal)
        startButton.isEnabled = false
        let request = VNCoreMLRequest(model: model) { (request, error) in
            self.processResult(for: request, error: error, originalImage: image)
        }
        request.imageCropAndScaleOption = .scaleFill
        n = Int(max(1, round(image.size.height / 512)))
        m = Int(max(1, round(image.size.width / 512)))
        m = min(m, 2)
        n = min(n, 2)
        let resizedImage = image.resized(newSize: CGSize(width: 512 * m, height: 512 * n))
        DispatchQueue.global(qos: .userInitiated).async {
            let cgImage = resizedImage.cgImage!
            //CGImagePropertyOrientation(
            //let orientation = CGImagePropertyOrientation(image.imageOrientation)
            var imagesMatrix: [[CGImage]] = []
            for i in 0..<self.n {
                var images: [CGImage] = []
                for j in 0..<self.m {
                    let cropped = cgImage.cropping(to: CGRect(x: j * 512, y: i * 512, width: 512, height: 512))!
                    images.append(cropped)
                }
                imagesMatrix.append(images)
            }
            
            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            for images in imagesMatrix {
                for img in images {
                    let handler = VNImageRequestHandler(cgImage: img, orientation: orientation)
                    do {
                        try handler.perform([request])
                    } catch {
                        print("Failed to perform classification.\n\(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    var images: [UIImage] = []
    
    func processResult(for request: VNRequest, error: Error?, originalImage: UIImage) {
        print(#function)
        DispatchQueue.main.async {
            
            guard let results = request.results as? [VNPixelBufferObservation] else {
                print("error", error ?? "")
                return
            }
            let ciImage = CIImage(cvPixelBuffer: results[0].pixelBuffer)
            let cgImage = self.convertCIImageToCGImage(inputImage: ciImage)!
            let uiImage = UIImage(cgImage: cgImage)
            self.images.append(uiImage)
            if self.images.count == self.n * self.m {
                var result = self.merge()
                result = result.resized(newSize: originalImage.size)
                self.move(image: result, originalImage: originalImage)
                self.images = []
            }
        }
    }
    
    func move(image: UIImage, originalImage: UIImage) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "SaveViewController") as! SaveViewController
        newViewController.image = image
        newViewController.originalImage = originalImage
        self.show(newViewController, sender: self)
        
        self.activityIndicator.stopAnimating()
        self.startButton.setTitle("Let's start", for: .normal)
        self.startButton.isEnabled = true
    }
}

extension ViewController {
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
    
    func merge() -> UIImage {
        // This is the rect that we've calculated out and this is what is actually used below
        

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 512 * m, height: 512 * n), false, 1.0)
        for (i, image) in images.enumerated() {
            let rect = CGRect(x: i % m * 512, y: i / m * 512, width: 512, height: 512)
            image.draw(in: rect)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension UIImage {
    func resized(newSize: CGSize) -> UIImage {
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}


