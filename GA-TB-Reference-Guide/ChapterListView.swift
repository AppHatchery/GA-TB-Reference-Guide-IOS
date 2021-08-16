//
//  TableOfContentsView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/6/21.
//

import SwiftUI

struct ChapterRow: View {
    var chapter: Chapter
    var body: some View {
            Text(chapter.title)
        }
}

// TODO: Replace static content with table of contents data shared between IOS and Android

// TODO: Skip SubChapterList if no Subchapters
struct ChapterListView: View {
    
    
    // TODO: If there are no subchapters, go directly to content
    var body: some View {
        List(chapters) { chapter in
            NavigationLink(destination: SubChapterListView(chapter: chapter)) {
                ChapterRow(chapter: chapter)
            }
        }
        .navigationTitle("All Chapters")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
}

struct TableOfContentsView_Previews: PreviewProvider {
    static var previews: some View {
        
        
        ChapterListView()
    }
}
