//
//  UIView+Extensions.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit

extension UIView {

    func dropShadow() {
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 2.0
//        layer.shadowColor = color
//        layer.cornerRadius = 2
//        layer.masksToBounds = false
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOpacity = 0.5
//        layer.shadowOffset = CGSize(width: 1, height: 1)
//        layer.shadowRadius = 2
//        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
//        layer.shouldRasterize = true
//        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func dropShadowNote() {
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 2.0
    }
    
    func setGradientBackground(size: CGRect) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.init(red: 156/255, green: 51/255, blue: 0, alpha: 1.0).cgColor, UIColor.init(red: 156/255, green: 51/255, blue: 0, alpha: 0.6).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = size

        layer.insertSublayer(gradientLayer, at: 0)        
    }
    
    func removeGradientBackground(){
        layer.sublayers?[0].removeFromSuperlayer()
    }
    
    
}
