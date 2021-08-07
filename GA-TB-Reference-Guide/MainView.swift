//
//  MainView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/6/21.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            
            GuideView()
                .tabItem { Label("Guide", systemImage:"list.dash") }
            
            
            SavedView()
                .tabItem { Label("Saved", systemImage:"list.dash") }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
