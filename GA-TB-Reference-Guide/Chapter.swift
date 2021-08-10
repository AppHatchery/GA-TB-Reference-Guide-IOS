//
//  Chapter.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/7/21.
//

import Foundation
import SwiftUI

struct Chapter: Identifiable {
    let id = UUID()
    let title: String
    var items: [Chapter]?
}
