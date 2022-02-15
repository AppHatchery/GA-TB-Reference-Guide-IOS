//
//  Settings.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 11/16/21.
//

import UIKit
import RealmSwift

class Settings: UIView {
    
    @IBOutlet weak var contactUs: UIButton!
    @IBOutlet weak var privacyPolicy: UIButton!
    @IBOutlet weak var about: UIButton!
    @IBOutlet weak var resetApp: UIButton!
    @IBOutlet weak var fontSize: UIButton!
    @IBOutlet weak var toggleNotifications: UISwitch!
    
    var contentViewTopConstraint: NSLayoutConstraint!
    let realm = try! Realm()
    var userSettings: UserSettings!

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
        
        // Realm
        try! realm.write
        {
            // Should only add a new entry if this entry is not already added there
            if let currentSettings = realm.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings"){
                toggleNotifications.setOn(currentSettings.pushNotifications, animated: false)
                // Assign the older entry to the current variable
                userSettings = currentSettings
                
            } else {
                userSettings = UserSettings()
                // Add it to Realm
                realm.add(userSettings)
            }
        }
    }

}
