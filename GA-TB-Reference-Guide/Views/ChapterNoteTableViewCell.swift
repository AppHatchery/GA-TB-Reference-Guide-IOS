//
//  ChapterNoteTableViewCell.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/14/21.
//

import UIKit

class ChapterNoteTableViewCell: UITableViewCell {

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var colorTag: UIView!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var edit: UIButton!
    @IBOutlet weak var shadowView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        shadowView.dropShadow()
        shadowView.layer.cornerRadius = 5
        shadowView.layer.borderWidth = 0.25
        shadowView.layer.borderColor = UIColor.lightGray.cgColor
        shadowView.dropShadowNote()
        
//        contentView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
