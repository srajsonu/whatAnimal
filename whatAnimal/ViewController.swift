//
//  ViewController.swift
//  whatAnimal
//
//  Created by ARY@N on 08/01/19.
//  Copyright © 2019 ARYAN. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let userPickedImage = info[.editedImage] as? UIImage {
            
            guard let ciimage = CIImage(image: userPickedImage) else {fatalError("Error to convert in CIImage")}
            detect(image: ciimage)
            
            //imageView.image = userPickedImage
            imagePicker.dismiss(animated: true, completion: nil)
        }else {
            print("Error while picking image")
        }
    }
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: ImageClassifier().model) else {fatalError("Can not retrieve model")}
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let classification = request.results?.first as? VNClassificationObservation else {fatalError("Could not classify image")}
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }catch {
            print(error)
        }
        
    }
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]

        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Go to the Wiki info")
                print(response)
                
                let animalJSON:JSON = JSON(response.result.value)
                
                let pageid = animalJSON["query"]["pageids"][0].stringValue
                
                let animalDescription = animalJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let animalImageURL = animalJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: animalImageURL))
                
                self.label.text = animalDescription
            }
        }
    }

    @IBAction func cameraTapped(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

