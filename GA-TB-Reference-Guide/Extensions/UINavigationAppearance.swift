//
//  UINavigationAppearance.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 1/31/22.
//

import UIKit

extension UINavigationBarAppearance {
    
    func setGradientBackground(to navController: UINavigationController) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.init(red: 156/255, green: 51/255, blue: 0, alpha: 1.0).cgColor, UIColor.init(red: 156/255, green: 51/255, blue: 0, alpha: 0.6).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = navController.navigationBar.bounds

        self.backgroundColor = gradientLayer as? UIColor
    }
}
