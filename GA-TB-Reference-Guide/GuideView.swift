//
//  GuideView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/6/21.
//

import SwiftUI

struct GuideView: View {
    var body: some View {
        
        NavigationView {
        
            NavigationLink(destination: TableOfContentsView()) {
                                Text("All Chapters")
            }
        
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(/*@START_MENU_TOKEN@*/.inline/*@END_MENU_TOKEN@*/)
        }
        
            
        }
}

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        GuideView()
    }
}
