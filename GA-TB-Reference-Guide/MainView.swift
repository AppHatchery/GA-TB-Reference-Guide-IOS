//
//  MainView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/6/21.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        
        // We declare two tabs here
        TabView {
            
            GuideView()
                .tabItem { Label("Guide", systemImage:"list.dash") }
            
            SavedView()
                .tabItem { Label("Saved", systemImage:"book") }
            
            ContactsView()
                .tabItem { Label("Contacts", systemImage:"person.circle") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage:"gear") }
            
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
