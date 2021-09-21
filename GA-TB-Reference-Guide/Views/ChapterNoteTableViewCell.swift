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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
