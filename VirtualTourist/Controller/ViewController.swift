//
//  ViewController.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 26.07.23.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBAction func buttonTapped(_ sender: UIButton) {
        FlickrClient().getPhotosInfoByLocation(CLLocationCoordinate2DMake(43, 28),completion: getPhotosInfoByloctaionCompleteHandler(response:error:))
    }
    
    func getPhotosInfoByloctaionCompleteHandler(response: SearchPhotosResponse?, error: Error?) {
        if let response = response {
            if let photo = response.photos.photo?.first {
                FlickrClient().getJpgPhoto(photo) { data, error in
                    guard let data = data else {
                        return
                    }
                    let image = UIImage(data: data)
                    self.imageView.image = image
                }
            }
        } else {
            if let error = error {
                showFailure(message: error.localizedDescription)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func showFailure(message: String, title: String = "Failed") {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
}

