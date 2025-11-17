//
//  SettingsViewsViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 11/16/21.
//

import UIKit
import WebKit
import RealmSwift

class SettingsViewsViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var url: URL!
    var titleLabel: String = "Settings"
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var fontSlider: UISlider!
    @IBOutlet weak var fontSize: UILabel!
    @IBOutlet var fontSizeElementCollection: [UIView]!
    
    var webView: WKWebView!
    var webViewTopConstraint: NSLayoutConstraint!
    var bottomAnchor: CGFloat = 0
    
    var fontSizeLabel: String = "Regular"
    var fontNumber: Int = 100
    let realm = RealmHelper.sharedInstance.mainRealm()
    var userSettings : UserSettings!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create WebView Content
        let config = WKWebViewConfiguration()
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        let navbarTitle = UILabel()
        navbarTitle.text = titleLabel
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.5
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        navigationItem.backButtonDisplayMode = .minimal
        
        setupUI()
        
        webView.load( URLRequest( url: url ))
        
        // Hide font size elements if reading About Us page
        if titleLabel == "About" {
            for fontElement in fontSizeElementCollection {
                fontElement.isHidden = true
            }
        }
        
        if let currentSettings = realm!.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings"){
            // Assign the older entry to the current variable
            userSettings = currentSettings
            sliderControl(state: userSettings.fontSize)
        } else {
            // Remake the font size if it doesn't exist: This is exclusively for instances where the user deletes it
            userSettings = UserSettings()
            // Add it to Realm
//            let realm = try! Realm()
            RealmHelper.sharedInstance.save(userSettings) { saved in
                //
            }
            sliderControl(state: 100)
        }
    }
    
    func setupUI() {
        contentView.addSubview(webView)
        
        webViewTopConstraint = webView.topAnchor
            .constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            webViewTopConstraint,
            webView.leftAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            webView.bottomAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,constant: -1*bottomAnchor),
            webView.rightAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -5)
        ])
    }
    
    @IBAction func fontSizeChanger(_ sender: UISlider){
        if fontSizeLabel == "Small" {
            if sender.value > 0.85 && sender.value < 1.15 {
                sliderControl(state: 100)
            } else if sender.value >= 1.15 && sender.value <= 1.5 {
                sliderControl(state: 150)
            } else if sender.value > 1.5 {
                sliderControl(state: 175)
            } else {
                sliderControl(state: 75)
            }
        } else if fontSizeLabel == "Regular"{
            if sender.value < 1.0 {
                sliderControl(state: 75)
            } else if sender.value > 1.2 && sender.value <= 1.5 {
                sliderControl(state: 150)
            } else if sender.value > 1.5 {
                sliderControl(state: 175)
            } else {
                sliderControl(state: 100)
            }
        } else if fontSizeLabel == "Large"{
            if sender.value > 0.95 && sender.value < 1.3 {
                sliderControl(state: 100)
            } else if sender.value <= 0.95 {
                sliderControl(state: 75)
            } else if sender.value > 1.5 {
                sliderControl(state: 175)
            } else {
                sliderControl(state: 150)
            }
        } else if fontSizeLabel == "Extra Large"{
            if sender.value > 0.95 && sender.value < 1.25 {
                sliderControl(state: 100)
            } else if sender.value <= 0.95 {
                sliderControl(state: 75)
            } else if sender.value < 1.65  && sender.value >= 1.25 {
                sliderControl(state: 150)
            } else {
                sliderControl(state: 175)
            }
        }
        
        RealmHelper.sharedInstance.update(userSettings, properties: [
            "fontSize":fontNumber
        ]) { updated in
            //
        }
        
//        try! realm!.write {
//            userSettings.fontSize = fontNumber
//        }
        webView.reload()
        
    }
    
    //--------------------------------------------------------------------------------------------------
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                
        if let urlHeader = webView.url?.absoluteString, urlHeader.hasPrefix("file:///"){
                        
            let textSize = fontNumber
            let javascript = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(textSize)%'"
            webView.evaluateJavaScript(javascript) { (response, error) in
                print("changed the font size to \(textSize)")
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        preferences.preferredContentMode = .mobile
        decisionHandler(.allow,preferences)
    }
    
    
    func sliderControl(state: Int){
        switch state {
        case 75:
            fontSlider.setValue(0.75, animated: false)
            fontNumber = 75
            fontSizeLabel = "Small"
        case 100:
            fontSlider.setValue(1.1, animated: false)
            fontNumber = 100
            fontSizeLabel = "Regular"
        case 150:
            fontSlider.setValue(1.4, animated: false)
            fontNumber = 150
            fontSizeLabel = "Large"
        case 175:
            fontSlider.setValue(1.75, animated: false)
            fontNumber = 175
            fontSizeLabel = "Extra Large"
        default:
            fontSlider.setValue(1.1, animated: false)
            fontNumber = 100
            fontSizeLabel = "Regular"
        }
        fontSize.text = "Font Size: \(fontSizeLabel)"
    }
}
