//
//  Guide.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 10/17/21.
//

import UIKit

class Guide: UIView {
    
    var contentViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var topQuickLinks: [UIButton]!
    @IBOutlet var bottomQuickLinks: [UIButton]!
    
    @IBOutlet weak var allChapters: UIButton!
    @IBOutlet weak var allCharts: UIButton!
    @IBOutlet weak var testbttn: UIButton!

    //------------------------------------------------------------------------------
    override init( frame: CGRect )
    {
        super.init( frame : frame )

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
        let nibView = (Bundle.main.loadNibNamed( "Guide", owner: self, options: nil)!.first as! UIView)
        self.addSubview( nibView )
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint( equalTo: self.leftAnchor ).isActive = true
        nibView.rightAnchor.constraint( equalTo: self.rightAnchor ).isActive = true
        nibView.bottomAnchor.constraint( equalTo: self.bottomAnchor ).isActive = true
        contentViewTopConstraint = nibView.topAnchor.constraint( equalTo: self.topAnchor )

        contentViewTopConstraint.isActive = true
        
        for button in topQuickLinks {
            button.layer.cornerRadius = 5
            button.dropShadow()
        }
        
        for button in bottomQuickLinks {
            button.layer.cornerRadius = 5
            button.titleLabel?.textAlignment = NSTextAlignment.center
            button.dropShadow()
        }
    }

}
