//
//  SavedView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/6/21.
//

import SwiftUI

struct shaderExample: View {
    
    let chapters = [I,II]

    var body: some View {
        List(chapters, children: \.items) { chapter in
            NavigationLink(destination: ContentView(chapter: chapter)) {
                ChapterRow(chapter: chapter)
            }
        }
    }
}

struct shaderExample_Previews: PreviewProvider {
    static var previews: some View {
        shaderExample()
    }
}
