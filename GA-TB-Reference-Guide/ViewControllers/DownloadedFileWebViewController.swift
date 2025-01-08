//
//  DownloadedFileWebViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 07/01/2025.
//

import UIKit
import WebKit

class DownloadedFileWebViewController: UIViewController, WKNavigationDelegate {
	var downloadedFile: String!
	var navTitle: String!
	var filename: String!
	// Remove @IBOutlet and initialize webView programmatically
	private var webView: WKWebView!

	override func viewDidLoad() {
		super.viewDidLoad()
		setupWebView()
		loadHTML()
		title = navTitle
	}

	private func setupWebView() {
		webView = WKWebView()
		webView.navigationDelegate = self
		view.addSubview(webView)

		webView.translatesAutoresizingMaskIntoConstraints = false
		webView.isOpaque = false
		webView.backgroundColor = .clear

		NSLayoutConstraint.activate([
			webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}

	private func loadHTML() {
		guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			print("Could not access documents directory")
			return
		}

		let filePath = documentsPath.appendingPathComponent(filename)

		if FileManager.default.fileExists(atPath: filePath.path) {
			webView.loadFileURL(filePath, allowingReadAccessTo: documentsPath)
		} else {
			print("File not found at path: \(filePath)")
		}
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		print("Page Loaded Successfully!")
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		print("Failed to load page: \(error.localizedDescription)")
	}
}
