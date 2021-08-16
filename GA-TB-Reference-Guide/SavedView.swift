//
//  SavedView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/7/21.
//

import SwiftUI

struct SavedView: View {
    
    @State private var searchText = ""
    
    let names = ["jupiter", "mars", "another planet"]
    
    var body: some View {
       
        NavigationView {
        List {
            
            SearchBar(text: $searchText)
            
            ForEach(self.names.filter {
                        self.searchText.isEmpty ? true : $0.localizedCaseInsensitiveContains(self.searchText)}
            
            , id: \.self) { name in
                Text(name)
            }
        }
        }
        
    }
    
}

struct SavedView_Previews: PreviewProvider {
    static var previews: some View {
        SavedView()
    }
}
