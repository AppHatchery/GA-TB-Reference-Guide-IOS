//
//  Notes.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/6/21.
//

import Foundation
import RealmSwift

@objcMembers
class Notes : Object
{
    dynamic var content : String = ""
    dynamic var lastEdited : String = ""
    dynamic var colorTag : Int = 0
    dynamic var subChapterName: String = ""
    dynamic var subChapterURL: String = ""
    dynamic var savedToRealm : Bool = false
    // Color UIColor is not supported by Realm so must convert it to float
//    dynamic var color : UInt32 = 0
    
    dynamic var id: Int = UUID().hashValue
    
    //--------------------------------------------------------------------------------------------------
    override static func primaryKey() -> String?
    {
        return "id"
    }
}
