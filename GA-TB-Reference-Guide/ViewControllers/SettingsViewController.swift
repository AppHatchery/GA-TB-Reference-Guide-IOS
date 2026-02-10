//
//  SettingsViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 11/16/21.
//

import UIKit
import RealmSwift
import FirebaseDynamicLinks

class SettingsViewController: UIViewController {

    var scrollView: UIScrollView!
    var settingsView: Settings!
    
    @IBOutlet weak var contentView: UIView!
    
    var url: URL!
    var header: String!
    var bottomAnchor: CGFloat!
    let realm = RealmHelper.sharedInstance.mainRealm()
    var userSettings: UserSettings!
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        let navbarTitle = UILabel()
        navbarTitle.text = "Settings"
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.7
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        navigationItem.backButtonDisplayMode = .minimal
                
        navigationController?.navigationBar.setGradientBackground(to: self.navigationController!)
        navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        if scrollView == nil {
            
            scrollView = UIScrollView( frame: view.frame )
            scrollView.backgroundColor = UIColor.clear
            contentView.addSubview( scrollView )
            scrollView.delaysContentTouches = false
                    
            settingsView = Settings(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
            scrollView.addSubview(settingsView)
                    
            scrollView.contentSize = CGSize(width: contentView.frame.width, height: 700)
            if let currentSettings = realm!.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings"){
                // Assign the older entry to the current variable
                userSettings = currentSettings
            }
        }
    }

    
    @IBAction func tapContactUs(_ sender: UIButton){
        let email = "support@apphatchery.org"
        if let url = URL(string: "mailto:\(email)") {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
          } else {
            UIApplication.shared.openURL(url)
          }
        }
    }
    
    @IBAction func tapPrivacyPolicy(_ sender: UIButton){
        url = Bundle.main.url(forResource: "georgia-tb-privacy-policy", withExtension: "html")!
        header = "Privacy Policy"
        bottomAnchor = 0
        performSegue(withIdentifier: "SegueToSettingsView", sender: nil)
    }
    
    @IBAction func tapAbout(_ sender: UIButton){
        url = Bundle.main.url(forResource: "about_us", withExtension: "html")!
        header = "About"
        bottomAnchor = 0
        performSegue(withIdentifier: "SegueToSettingsView", sender: nil)
    }
    
    @IBAction func tapFontSize(_ sender: UIButton){
        url = Bundle.main.url(forResource: "quote", withExtension: "html")!
        header = "Text Size"
        bottomAnchor = 200.0
        performSegue(withIdentifier: "SegueToSettingsView", sender: nil)
    }
    
    @IBAction func toggleNotifications(_ sender: UISwitch){
        RealmHelper.sharedInstance.update(userSettings, properties:[
            "pushNotifications": sender.isOn
        ]) { updated in
            //
            if sender.isOn {
                print("notifications are on")
            } else {
                print("notifications are off")
            }
        }
//        try! realm!.write {
//            userSettings.pushNotifications = sender.isOn
//            if sender.isOn {
//                print("notifications are on")
//            } else {
//                print("notifications are off")
//            }
//        }
    }
    
    // Toggle Light/Dark Mode, but need to reset to default state too so probably need to move to the next view controller
    
    // Unless the toggle can be to manually override to light or dark contrary to the users default mode 
//    @IBAction func toggleLightMode(_ sender: UISwitch){
//        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
//        let sceneDelegate = windowScene.delegate as! SceneDelegate
//
//        if let window = sceneDelegate.window
//        {
//            window.overrideUserInterfaceStyle = .dark
//        }
//    }
    
    @IBAction func tapReset(_ sender: UIButton){
        guard let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        TwoOptionsPopUp.show(
            in: window,
            label: "This will permanently clear all your saved bookmarks, notes and settings. Are you sure you want to proceed?",
            cancelTitle: "No",
            deleteTitle: "Yes",
            onCancel: nil,
            onDelete: { [weak self] in
                guard let self = self else { return }
                // Delete the realm contents
                try? self.realm?.write {
                    self.realm?.deleteAll()
                }

                if let windowScene = UIApplication.shared.connectedScenes
                    .filter({ $0.activationState == .foregroundActive })
                    .first as? UIWindowScene,
                   let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                        CustomPopUp.showTemporary(in: window, popupLabelText: "App reset successfully")
                }
            }
        )
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let settingsViewController = segue.destination as? SettingsViewsViewController
        {
            settingsViewController.url = url
            settingsViewController.titleLabel = header
            settingsViewController.bottomAnchor = bottomAnchor
        }
    }
}
