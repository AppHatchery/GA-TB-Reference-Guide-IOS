//
//  UserSettings.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 12/30/21.
//

import Foundation
import RealmSwift

@objcMembers
class UserSettings : Object
{
    dynamic var fontSize : Int = 100
    dynamic var pushNotifications : Bool = true
    
    dynamic var id: String = "savedSettings"
    
    //--------------------------------------------------------------------------------------------------
    override static func primaryKey() -> String?
    {
        return "id"
    }
}
