//
//  SavedTabEmptyState.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 11/21/21.
//

import Foundation
import UIKit
import WebKit

class FeedbackForm: UIView {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var webview: WKWebView!
    
    // Dialog Constraints
    @IBOutlet weak var dialogLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var dialogRightConstraint: NSLayoutConstraint!
        
    var contentViewTopConstraint: NSLayoutConstraint!
    var parent: String = ""
    var title: String = ""

    //------------------------------------------------------------------------------
    init( frame: CGRect, parent: String, title: String )
    {
        super.init( frame : frame )
    
        self.parent = parent
        self.title = title

        customInit()
    }
    
    //------------------------------------------------------------------------------
    required init?( coder aDecoder: NSCoder )
    {
        super.init( coder : aDecoder )
        
        customInit()
    }
    
    //------------------------------------------------------------------------------
    func customInit()
    {
        let nibView = (Bundle.main.loadNibNamed( "FeedbackForm", owner: self, options: nil)!.first as! UIView)
        self.addSubview( nibView )
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint( equalTo: self.leftAnchor ).isActive = true
        nibView.rightAnchor.constraint( equalTo: self.rightAnchor ).isActive = true
        nibView.bottomAnchor.constraint( equalTo: self.bottomAnchor ).isActive = true
        contentViewTopConstraint = nibView.topAnchor.constraint( equalTo: self.topAnchor )
        
        if self.frame.width > 1000 {
            dialogLeftConstraint.constant = 240
            dialogRightConstraint.constant = 240
        }

        contentViewTopConstraint.isActive = true
        
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
        
        closeButton.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        
        // Load webview
        let parentChapter = parent.replacingOccurrences(of: " ", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
        let subChapter = title.replacingOccurrences(of: " ", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "γ", with: "")
        print("https://emorymedicine.sjc1.qualtrics.com/jfe/form/SV_4NEG4bjuyBGono9?page="+"chapter:\(parentChapter)_subchapter:\(subChapter)")
        webview.load( URLRequest( url: URL(string: "https://emorymedicine.sjc1.qualtrics.com/jfe/form/SV_4NEG4bjuyBGono9?page="+"chapter:\(parentChapter)_subchapter:\(subChapter)")! ))
    }
    
    //------------------------------------------------------------------------------
    @objc func cancelButtonPressed()
    {
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            self.removeFromSuperview()
        })
    }
}
