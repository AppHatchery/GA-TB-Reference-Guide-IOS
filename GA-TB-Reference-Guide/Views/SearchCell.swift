//
//  SearchCell.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/4/21.
//

import UIKit

class SearchCell: UITableViewCell {
    
    @IBOutlet weak var subchapterLabel: UILabel!
    @IBOutlet weak var chapterLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
