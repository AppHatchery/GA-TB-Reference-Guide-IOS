//
//  SwiftUISearchBarView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/9/21.
//

import SwiftUI

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(_ text: Binding<String>) {
            _text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
            print("THe text changed to", searchText)
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            // Stop doing the search stuff
                // and clear the text in the search bar
                searchBar.text = ""
                // Hide the cancel button
                searchBar.showsCancelButton = false
                // You could also change the position, frame etc of the searchBar
                searchBar.endEditing(true)
        }
        
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.showsCancelButton = true
        searchBar.placeholder = "Search"
        searchBar.delegate = context.coordinator
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator($text)
    }
}
