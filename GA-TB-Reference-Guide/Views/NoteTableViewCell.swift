//
//  NoteTableViewCell.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/12/21.
//

import UIKit

class NoteTableViewCell: UITableViewCell {

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var colorTag: UIView!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var linkToChapter: UILabel!
    @IBOutlet weak var shadowView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        shadowView.layer.cornerRadius = 5
        shadowView.layer.borderWidth = 0.25
        shadowView.layer.borderColor = UIColor.lightGray.cgColor
        shadowView.dropShadowNote()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
