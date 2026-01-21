//
//  NoteSavedPopUp.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 09/10/2025.
//

import UIKit

protocol NoteSavedPopUpDelegate {
    func didTapVisitSettings()
}

class NoteSavedPopUp: UIView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var visitButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBOutlet var buttons: [UIButton]!
        
    var contentViewTopConstraint: NSLayoutConstraint!
    var delegate: NoteSavedPopUpDelegate?
        
    init(frame: CGRect, delegate: NoteSavedPopUpDelegate? = nil) {
        super.init(frame: frame)
        
        self.delegate = delegate
        
        customInit()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        customInit()
    }
    
    
    func customInit() {
        let nibView = (Bundle.main.loadNibNamed("NoteSavedPopUp", owner: self, options: nil)!.first as! UIView)
        self.addSubview(nibView)
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        nibView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentViewTopConstraint = nibView.topAnchor.constraint(equalTo: self.topAnchor)
        
        contentViewTopConstraint.isActive = true
        
        mainView.layer.cornerRadius = 4
        mainView.layer.masksToBounds = true
        
        contentLabel.setText(
            "Thank you for your valuable feedback! If you want to get follow-ups on this feedback, Please go to Contact Us on Settings page",
            highlightedStrings: ["Contact Us", "Settings"])

        
        for button in buttons {
            button.layer.cornerRadius = 0
            button.layer.masksToBounds = true
            button.layer.borderWidth = 0
        }
        
        visitButton.addTarget(self, action: #selector(visitButtonPressed), for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(dismissButtonPressed), for: .touchUpInside)
    }
    
    
    @objc func visitButtonPressed() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backgroundView.alpha = 0
            self.mainView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.delegate?.didTapVisitSettings()
            self.removeFromSuperview()
        })
    }
    
    
    @objc func dismissButtonPressed() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backgroundView.alpha = 0
            self.mainView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
    
    
    // Convenience method to show the popup
    static func show(in window: UIWindow, delegate: NoteSavedPopUpDelegate? = nil) {
        let popup = NoteSavedPopUp(frame: window.bounds, delegate: delegate)
        popup.mainView.transform = CGAffineTransform(scaleX: 0, y: 0)
        popup.backgroundView.alpha = 0
        
        window.addSubview(popup)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            popup.backgroundView.alpha = 0.5
            popup.mainView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
}
