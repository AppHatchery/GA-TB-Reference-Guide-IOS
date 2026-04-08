//
//  UITextField+Extensions.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 06/06/2025.
//

import Foundation
import UIKit

extension UITextField {
	func setSearchIcon(_ image: UIImage?, tintColor: UIColor) {
		let iconView = UIImageView(image: image?.withRenderingMode(.alwaysTemplate))
		iconView.tintColor = tintColor
		leftView = iconView
	}

	func setClearButton(_ image: UIImage?, tintColor: UIColor) {
		if let clearButton = value(forKey: "_clearButton") as? UIButton {
			if let customImage = image?.withRenderingMode(.alwaysTemplate) {
				clearButton.setImage(customImage, for: .normal)
			}
			clearButton.tintColor = tintColor
		}
	}
}
