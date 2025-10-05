//
//  ChapterNoteTableViewCell.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/14/21.
//

import UIKit

class ChapterNoteTableViewCell: UITableViewCell {

    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var colorTag: UIView!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var edit: UIButton!
    @IBOutlet weak var mainView: UIView!
    
    var onEditTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
//        shadowView.dropShadow()
        parentView.layer.cornerRadius = 4
        mainView.layer.cornerRadius = 4
        colorTag.layer.cornerRadius = 4
        colorTag.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner] // Left corners only
//        shadowView.dropShadowNote()
        
//        contentView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        edit.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc private func editButtonTapped() {
        onEditTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onEditTapped = nil
    }
}
