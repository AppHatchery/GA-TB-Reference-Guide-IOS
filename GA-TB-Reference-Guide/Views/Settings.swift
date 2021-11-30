//
//  Settings.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 11/16/21.
//

import UIKit

class Settings: UIView {
    
    @IBOutlet weak var contactUs: UIButton!
    @IBOutlet weak var privacyPolicy: UIButton!
    @IBOutlet weak var about: UIButton!
    @IBOutlet weak var resetApp: UIButton!
    
    var contentViewTopConstraint: NSLayoutConstraint!

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
        let nibView = (Bundle.main.loadNibNamed( "Settings", owner: self, options: nil)!.first as! UIView)
        self.addSubview( nibView )
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        contentViewTopConstraint = nibView.topAnchor.constraint( equalTo: self.topAnchor )

        contentViewTopConstraint.isActive = true
        nibView.leftAnchor.constraint( equalTo: self.leftAnchor ).isActive = true
        nibView.rightAnchor.constraint( equalTo: self.rightAnchor ).isActive = true
        nibView.bottomAnchor.constraint( equalTo: self.bottomAnchor ).isActive = true
    }

}
