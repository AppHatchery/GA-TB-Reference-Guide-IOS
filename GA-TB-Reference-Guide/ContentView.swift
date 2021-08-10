//
//  ContentView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/7/21.
//

import SwiftUI

struct ContentView: View {
    let chapter: Chapter
    
    var body: some View {
    
        let url = Bundle.main.url(forResource: chapter.title, withExtension: "html")!
        
            SwiftUIWebView(url: url)
                .navigationTitle(chapter.title)
                .navigationBarTitleDisplayMode(.inline)
                .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        let example = Chapter(title: "I.Epidemiology")
        ContentView(chapter: example )
        
    }
}
