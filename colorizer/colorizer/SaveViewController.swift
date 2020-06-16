//
//  SaveViewController.swift
//  colorizer
//
//  Created by Максим Ефимов on 26.05.2020.
//  Copyright © 2020 Максим Ефимов. All rights reserved.
//

import UIKit
import StoreKit

class SaveViewController: UIViewController {
    var image: UIImage!
    var originalImage: UIImage!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.image = image
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
        self.navigationController?.view.backgroundColor = .clear
        
        let backButton = UIBarButtonItem()
        backButton.title = ""
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
        saveButton.layer.masksToBounds = true
        saveButton.layer.cornerRadius = 6
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTap)))
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        let imageShare = [ image! ]
        let activityViewController = UIActivityViewController(activityItems: imageShare , applicationActivities: [])
        activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if !completed {
                return
            }
            let ac = UIAlertController(title: "Saved!", message: "Your colorized photo has been saved.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
        activityViewController.popoverPresentationController?.sourceView = saveButton
        self.present(activityViewController, animated: true)
        //UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Int.random(in: 0..<4) == 2 {
            SKStoreReviewController.requestReview()
        }
    }
    
    @objc func imageTap() {
        if self.imageView.image == image {
            self.imageView.image = originalImage
        } else {
            self.imageView.image = image
        }
    }
}
