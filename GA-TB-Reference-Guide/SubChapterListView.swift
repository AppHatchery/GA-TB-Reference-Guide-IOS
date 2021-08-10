//
//  SubChapterList.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/7/21.
//

import SwiftUI

struct SubChapterListView: View {
    let chapter: Chapter
    
    var body: some View {
        List(chapter.items!) { item in
            NavigationLink(destination: ContentView(chapter: item)) {            ChapterRow(chapter: item)
            }
        }
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        
        }
}


struct SubChapterList_Previews: PreviewProvider {
    static var previews: some View {
        
        let example = Chapter(title: "I.Epidemiology")
        SubChapterListView(chapter: example)
    }
}
