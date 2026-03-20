//
//  SuggestionTableViewCell.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 30/07/2024.
//

import UIKit

/// SuggestionTableViewCell defines a reusable table view cell UI.
class SuggestionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var suggestionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        /// Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        /// Configure the view for the selected state
    }
    
}
