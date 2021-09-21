//
//  ContentAccess.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/6/21.
//

import Foundation
import RealmSwift

@objcMembers
class ContentAccess : Object
{
    dynamic var name : String = ""
    dynamic var url : String = ""
    dynamic var chapterParent : String = ""
    
    dynamic var id: Int = UUID().hashValue
    
    //--------------------------------------------------------------------------------------------------
    override static func primaryKey() -> String?
    {
        return "id"
    }
}
