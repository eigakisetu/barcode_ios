//
//  CartListsTableViewCell.swift
//  teburaFrontApp
//
//  Created by 佐竹映季 on 2017/10/30.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import UIKit

class CartListsTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        self.titleLabel.text = nil
        self.priceLabel.text = nil
        self.thumbnailView.image = nil
    }
}
