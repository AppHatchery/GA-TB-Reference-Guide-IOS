//
//  ExampleData.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/7/21.
//

import Foundation
import UIKit

//TODO: Add the rest of the chapters

// Subchapters
let IA = Chapter(title: "I. Epidemiology")
let IIintro = Chapter(title: "II. Introduction")
let IIA = Chapter(title: "A. Tuberculin Skin Test (TST)")
let IIB = Chapter(title: "B. Criteria for a Positive Tuberculin Test, by Risk Group")

// Chapters
let I = Chapter(title: "I. Epidemiology", items:[IA])
let II = Chapter(title: "II. Diagnostic Tests for Latent TB Infection (LTBI)", items: [IIintro, IIA, IIB])

let chapters = [I,II]

let lightBrown = UIColor(red: 1, green: 165/255, blue: 0, alpha: 0.3)
let darkBrown = UIColor(red: 158/255, green: 62/255, blue: 15/255, alpha: 0.66)

