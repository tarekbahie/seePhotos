//
//  ViewController.swift
//  seeFoad
//
//  Created by tarek bahie on 2/13/19.
//  Copyright © 2019 tarek bahie. All rights reserved.
//

import UIKit
import VisualRecognitionV3
import SVProgressHUD
import TwitterKit
import SafariServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    let apiKey = "h2LKsBKuA-li5vNkCdGFidJsoF7u_RsBOeCuTJlG3ZPG"
    let version = "2019-02-13"
    
    @IBOutlet weak var itemLbl: UILabel!
    @IBOutlet weak var itemImg: UIImageView!
    @IBOutlet weak var cameraBtn: UIBarButtonItem!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var logoutBtn: UIButton!
    
    
    
    
    var imagePicker = UIImagePickerController()
    var classificationNamesArray: [String]=[]
    var classificationConfidenceArray: [Double]=[]
    var itemName = ""
    var score : Double = 0.0
    var indexLocation : Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker.delegate = self
        self.imagePicker.allowsEditing = true
        self.itemLbl.text = "Pick an image and i will predict what is it 😎 "
        shareBtn.isHidden = true
        logoutBtn.isHidden = true
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return TWTRTwitter.sharedInstance().application(app, open: url, options: options)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if TWTRTwitter.sharedInstance().sessionStore.session() == nil {
            let logInButton = TWTRLogInButton(logInCompletion: { session, error in
                if (session != nil) {
                    print("signed in as \(session?.userName)")
                    
                    
                } else {
                    print("error: \(error?.localizedDescription)");
                }
            })
            
            logInButton.center = self.view.center
            self.view.addSubview(logInButton)
            shareBtn.isHidden = false
            
        }
    }
    
    
    
    
    @IBAction func cameraBtnPressed(_ sender: Any) {
        if self.classificationConfidenceArray.count > 0 && self.classificationNamesArray.count > 0 {
            self.classificationConfidenceArray.removeAll()
            self.classificationNamesArray.removeAll()
        }
        self.itemLbl.text = ""
        
        let photoAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        photoAlert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (UIAlertAction) in
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        photoAlert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (UIAlertAction) in
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true, completion: nil)
        }))
        photoAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (UIAlertAction) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(photoAlert, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        cameraBtn.isEnabled = false
        SVProgressHUD.show()
        if let userPickedImage = info[.editedImage] as? UIImage {
            self.itemImg.image = userPickedImage
            self.itemImg.contentMode = .scaleAspectFill
            imagePicker.dismiss(animated: true, completion: nil)
            let visualRecognition = VisualRecognition(version: version, apiKey: apiKey)
            let imageData = userPickedImage.jpegData(compressionQuality: 0.01)
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileUrl = documentsUrl.appendingPathComponent("tempImage.jpg")
            try? imageData?.write(to: fileUrl, options: [])
            visualRecognition.classify(imagesFile: fileUrl) { (response, error) in
                if let error = error {
                    print(error)
                    return
                }
                guard let classifiedImages = response?.result else {
                    
                    print("Failed to classify the image")
                    
                    return
                    
                }
                let classes = classifiedImages.images.first!.classifiers.first!.classes
                for index in 0..<classes.count {
                    if classes[index].score > 0.5{
                        self.classificationNamesArray.append(classes[index].className)
                        self.classificationConfidenceArray.append(classes[index].score)
                    }
                }
                var firstScore = 0.0
                var newIndex: Int = 0
                for index in 0..<self.classificationConfidenceArray.count {
                    if self.classificationConfidenceArray[index] > firstScore {
                        firstScore = self.classificationConfidenceArray[index]
                        newIndex = index
                    }
                }
                self.score = firstScore
                let percentage = floor(self.score * 100)
                self.indexLocation = newIndex
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.itemLbl.text = "This is a \(self.classificationNamesArray[self.indexLocation]). I'm \(percentage)% sure"
                    self.cameraBtn.isEnabled = true
                    self.shareBtn.isHidden = false
                    self.logoutBtn.isHidden = false
                }
                print("Classified Images -> \(self.classificationNamesArray)")
                print("Score -> \(self.classificationConfidenceArray)")
                
            }
            
        }else {
            print("there was an error picking the image")
        }
        
    }
    
    @IBAction func shareBtnPressed(_ sender: Any) {
            if TWTRTwitter.sharedInstance().sessionStore.session() == nil {
        let logInButton = TWTRLogInButton(logInCompletion: { session, error in
            if (session != nil) {
                print("signed in as \(session?.userName)")
                
                
            } else {
                print("error: \(error?.localizedDescription)");
            }
        })
        
        logInButton.center = self.view.center
        self.view.addSubview(logInButton)
                shareBtn.isHidden = false
        
    }
        let composer = TWTRComposer()
        
        composer.setText("\(self.itemLbl.text!)")
        composer.setImage(itemImg.image!)
        
        // Called from a UIViewController
        composer.show(from: self) { (result) in
            if result == .done {
                print("Successfuly tweeted")
            } else {
                print("Cancelled composing")
            }
        }
    }
    
    
    @IBAction func logoutBtnPressed(_ sender: Any) {
        logoutTwitter()
    }
    
    
    
    
    
    func logoutTwitter() {
        let store = TWTRTwitter.sharedInstance().sessionStore
        if let userID = store.session()?.userID {
            store.logOutUserID(userID)
            shareBtn.isHidden = true
        }
    }
}

