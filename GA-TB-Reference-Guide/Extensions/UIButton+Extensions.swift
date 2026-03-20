//
//  UIButton+Extensions.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 12/27/21.
//

import UIKit

extension UIButton {
    
    func setDynamicFontSize() {
        NotificationCenter.default.addObserver(self, selector: #selector(setButtonDynamicFontSize),name: UIContentSizeCategory.didChangeNotification,object: nil)
    }
    
    @objc func setButtonDynamicFontSize() {
        Common.setButtonTextSizeDynamic(button: self, textStyle: .callout)
    }
}

/// Common provides related app functionality.
class Common {
    
    /// Sets the button text size dynamically based on the content size category.
    class func setButtonTextSizeDynamic(button: UIButton, textStyle: UIFont.TextStyle) {
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: textStyle)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
}
