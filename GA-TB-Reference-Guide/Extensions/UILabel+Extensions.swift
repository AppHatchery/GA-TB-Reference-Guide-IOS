//
//  UILabel+Extensions.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 08/10/2025.
//

import UIKit

extension UILabel {
    func setText(_ text: String, highlightedStrings: [String], highlightColor: UIColor = .colorPrimary) {
        let attributedText = NSMutableAttributedString(string: text)
        
        for word in highlightedStrings {
            let range = (text as NSString).range(of: word)
            if range.location != NSNotFound {
                attributedText.addAttribute(.foregroundColor, value: highlightColor, range: range)
                // attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: self.font.pointSize), range: range)
            }
        }
        
        self.attributedText = attributedText
    }
}
