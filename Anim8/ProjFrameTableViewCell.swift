//
//  ProjFrameTableViewCell.swift
//  Anim8
//
//  Created by Jacob Kittley-Davies on 14/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

import UIKit

class ProjFrameTableViewCell: UITableViewCell {
    
    @IBOutlet var thumbView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            layer.borderColor = UIColor.orange.cgColor
            layer.borderWidth = 4.0
        } else {
            layer.borderColor = UIColor.orange.cgColor
            layer.borderWidth = 0.0
        }
        // Configure the view for the selected state
    }

}
