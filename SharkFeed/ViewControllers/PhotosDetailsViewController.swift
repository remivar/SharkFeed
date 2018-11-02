//
//  PhotosDetailsViewController.swift
//  SharkFeed
//
//  Created by Remi on 12/09/17.
//  Copyright © 2016 Remi. All rights reserved.
//

import UIKit

class PhotosDetailsViewController: UIViewController {

    var selectedPhoto: PhotosDetails!
    
    @IBOutlet weak var photoDisplay: UIImageView!
    @IBOutlet weak var titleDisplay: UILabel!
    @IBOutlet weak var descriptionDisplay: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(selectedPhoto)
        print(selectedPhoto.photoTitle)
        
        //self.photoDisplay.image = UIImage(named: "loading.png")
        self.titleDisplay.text = selectedPhoto.photoTitle as String
        self.titleDisplay.backgroundColor = UIColor.clear
        self.descriptionDisplay.text = ""
        
        let url: URL = URL(string: selectedPhoto.lthumbnailURL as String)!
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url)
            DispatchQueue.main.async {
                if data != nil {
                    self.photoDisplay.image = UIImage(data: data!)
                }
            }
        }
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Image downloading to camera roll
    @IBAction func downloadImage(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(self.photoDisplay.image!, self, nil, nil)
    }
    
}
