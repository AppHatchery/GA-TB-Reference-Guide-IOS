//
//  BookmarkTableViewCell.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 29/09/2025.
//

import UIKit

class BookmarkTableViewCell: UITableViewCell {

    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var sideView: UIView!
    
    @IBOutlet weak var chapterTitleLabel: UILabel!
    @IBOutlet weak var chapterTitleSmallLabel: UILabel!
    @IBOutlet weak var subchapterTitleLabel: UILabel!

    @IBOutlet weak var editBookmarkButton: UIButton!
    
    @IBOutlet weak var chapterIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        mainView.layer.cornerRadius = 4
        sideView.layer.cornerRadius = 4
        sideView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner] // Left corners only
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
