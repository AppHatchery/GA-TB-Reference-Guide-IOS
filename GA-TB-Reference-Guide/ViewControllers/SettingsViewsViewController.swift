//
//  SettingsViewsViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 11/16/21.
//

import UIKit
import WebKit

class SettingsViewsViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var url: URL!
    @IBOutlet weak var contentView: UIView!
    
    var webView: WKWebView!
    var webViewTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create WebView Content
        let config = WKWebViewConfiguration()
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        setupUI()
        
        webView.load( URLRequest( url: url ))
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        contentView.addSubview(webView)
        
        webViewTopConstraint = webView.topAnchor
            .constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            webViewTopConstraint,
            webView.leftAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            webView.bottomAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            webView.rightAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -5)
        ])
    }
}
