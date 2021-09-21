//
//  ContentPage.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/6/21.
//

import Foundation
import RealmSwift

@objcMembers
class ContentPage : Object
{
    dynamic var name : String = ""
    dynamic var url : String = ""
    dynamic var chapterParent : String = ""
    dynamic var favorite : Bool = false
    dynamic var favoriteName : String = ""
    dynamic var lastOpened : Date = Date()
    dynamic var openedTimes : Int = 0
    dynamic var hasNotes : Bool = false
    dynamic var isHistory : Bool = false
    let notes = List<Notes>()
    
    dynamic var id: Int = UUID().hashValue
    
    //--------------------------------------------------------------------------------------------------
    override static func primaryKey() -> String?
    {
        return "url"
    }
}
