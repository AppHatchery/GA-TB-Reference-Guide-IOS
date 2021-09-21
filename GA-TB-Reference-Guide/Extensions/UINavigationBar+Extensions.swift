//
//  UIViewController+Extensions.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit

extension UINavigationBar {
    
    func setGradientBackground(to navController: UINavigationController) {
        
        let gradient = CAGradientLayer()
        var bounds = navController.navigationBar.bounds
        bounds.size.height += window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        gradient.frame = bounds
        gradient.colors = [UIColor.init(red: 156/255, green: 51/255, blue: 0, alpha: 1.0).cgColor, UIColor.init(red: 156/255, green: 51/255, blue: 0, alpha: 0.6).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        
        
        
        if let image = getImageFrom(gradientLayer: gradient) {
            navController.navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
            navController.navigationBar.shadowImage = UIImage()
            navController.navigationBar.layoutIfNeeded()
        }
    }
    
    func getImageFrom(gradientLayer:CAGradientLayer) -> UIImage? {
        var gradientImage:UIImage?
        UIGraphicsBeginImageContext(gradientLayer.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            gradientImage = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        }
        UIGraphicsEndImageContext()
        return gradientImage
    }
    
}
