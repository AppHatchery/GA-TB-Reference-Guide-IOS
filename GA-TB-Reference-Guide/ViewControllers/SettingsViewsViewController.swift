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
    @IBOutlet weak var contentView: UIView!

    var url: URL!
    var titleLabel: String = "Settings"
    
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
        navbarTitle.minimumScaleFactor = 0.7
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        navigationItem.backButtonDisplayMode = .minimal
        
        setupUI()
        
        webView.load( URLRequest( url: url ))
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
}
