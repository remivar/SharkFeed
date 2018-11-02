//
//  CustomCollectionViewCell.swift
//  SharkFeed
//
//  Created by Kishore on 12/09/17.
//  Copyright © 2016 Kishore. All rights reserved.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    
    //When we use below outlet, crahes with unexpected nil while setting loading image to cell in the cellItem method
    @IBOutlet var imageView1: UIImageView!
}
