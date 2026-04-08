//
//  ThemeManager.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 07/10/2025.
//

import UIKit

/// ThemeManager centralizes related app data or service logic.
class ThemeManager {
    static let shared = ThemeManager()
    private let darkModeKey = "darkModeEnabled"
    
    private init() {}
    
    /// apply Stored Theme.
    func applyStoredTheme() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            if UserDefaults.standard.object(forKey: darkModeKey) != nil {
                let isDarkMode = UserDefaults.standard.bool(forKey: darkModeKey)
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
    
    /// set Theme.
    func setTheme(isDarkMode: Bool) {
        UserDefaults.standard.set(isDarkMode, forKey: darkModeKey)
        applyInterfaceStyle(isDarkMode: isDarkMode)
    }
    
    private func applyInterfaceStyle(isDarkMode: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }
}
