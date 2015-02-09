//
//  PlayerTableViewCell.swift
//  bluechipper
//
//  Created by Nicholas Clark on 11/22/14.
//  Copyright (c) 2014 Nicholas Clark. All rights reserved.
//

import UIKit
import CoreBluetooth

class PlayerTableViewCell: UITableViewCell {
  @IBOutlet var nameLabel : UILabel!
  @IBOutlet var descriptionLabel : UILabel!
  @IBOutlet var orderLabel : UILabel!
  @IBOutlet var pictureImage : PFImageView!
}
