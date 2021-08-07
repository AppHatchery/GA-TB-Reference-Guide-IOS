//
//  TableOfContentsView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/6/21.
//

import SwiftUI

struct TableOfContentsView: View {
    var body: some View {
        
        List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
                    
                    VStack(alignment: .leading) {
                        Text("Simon Ng")
                    }
                }
    }
}

struct TableOfContentsView_Previews: PreviewProvider {
    static var previews: some View {
        TableOfContentsView()
    }
}
