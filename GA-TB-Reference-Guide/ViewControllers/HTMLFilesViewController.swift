//
//  HTMLFilesViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 08/01/2025.
//

import Foundation
import UIKit

class HTMLFilesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	private let tableView = UITableView()
	private var htmlFiles: [String] = []

	override func viewDidLoad() {
		super.viewDidLoad()
		setupTableView()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		loadHTMLFiles()
	}

	private func setupTableView() {
		view.addSubview(tableView)
		tableView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			tableView.topAnchor.constraint(equalTo: view.topAnchor),
			tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FileCell")
	}

	private func loadHTMLFiles() {
		guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return
		}

		do {
			let files = try FileManager.default.contentsOfDirectory(at: documentsPath,
			                                                        includingPropertiesForKeys: nil,
			                                                        options: .skipsHiddenFiles)
			htmlFiles = files.filter { $0.pathExtension == "html" }
				.map { $0.lastPathComponent }
			tableView.reloadData()
		} catch {
			print("Error loading files: \(error)")
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return htmlFiles.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath)
		cell.textLabel?.text = htmlFiles[indexPath.row]
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		let filename = htmlFiles[indexPath.row]
		let webViewController = DownloadedFileWebViewController()
//		let webViewController = WebViewViewController()
		webViewController.filename = filename
		navigationController?.pushViewController(webViewController, animated: true)
	}

//	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//		if let webViewViewController = segue.destination as? WebViewViewController {
//			webViewViewController.navTitle = "HTML PAGE"
//			webViewViewController.hidesBottomBarWhenPushed = true
//		}
//	}
}
