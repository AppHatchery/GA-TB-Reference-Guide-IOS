//
//  Search.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 01/08/2024.
//

import Foundation
import RealmSwift

@objcMembers
/// Search centralizes related app data or service logic.
class Search: Object {
    dynamic var recentSearch: String = ""
    
    override static func primaryKey() -> String? {
        return "recentSearch"
    }
}
