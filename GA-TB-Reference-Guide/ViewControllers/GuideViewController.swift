//
//  GuideViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//
import FirebaseDynamicLinks
import Network
import RealmSwift
import UIKit

class GuideViewController: UIViewController, URLSessionDownloadDelegate {
	@IBOutlet var topQuickLinks: [UIButton]!
	@IBOutlet var bottomQuickLinks: [UIButton]!

	@IBOutlet var contentView: UIView!

	private var downloadTask: URLSessionDownloadTask!
	private var downloadSession: URLSession!
	private var networkMonitor: NWPathMonitor?
	private var isConnected = true

	var scrollView: UIScrollView!
	var guideView: Guide!
	var url: URL!
	var header: String!

	var quickTitle = ""
	var quickPointer = 0

	let bible = ChapterIndex()

	var isGradientAdded = false

	let downloadManager = BatchDownloadManager()

	func startBatchDownload() {
		// TODO: Refactor this so that the filename is automatically generated based on the URL's file

		let filesToDownload = [
			(url: "https://tbguide.framer.website/tb-coordinator", filename: "15_appendix_district_tb_coordinators_(by_district).html"),
		]

		downloadManager.startBatchDownload(files: filesToDownload)
	}

	func copyBundleFilesToDocuments() {
		guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return
		}

		// Get URL to the bundle folder containing HTML files
		guard let bundleFolderPath = Bundle.main.path(forResource: "YourFolderName", ofType: nil) else {
			return
		}

		do {
			let files = try FileManager.default.contentsOfDirectory(atPath: bundleFolderPath)
			for file in files where file.hasSuffix(".html") {
				let bundleFile = (bundleFolderPath as NSString).appendingPathComponent(file)
				let documentsFile = documentsPath.appendingPathComponent(file)

				// Copy if doesn't exist
				if !FileManager.default.fileExists(atPath: documentsFile.path) {
					try FileManager.default.copyItem(atPath: bundleFile, toPath: documentsFile.path)
				}
				print("COPYING \(file)")
			}
		} catch {
			print("Error copying files: \(error)")
		}
	}

	//    var search = UISearchController(searchResultsController: nil) // Declare the searchController

	@objc func downloadsCompleted() {
		// Handle completion, perhaps reload your UI
		print("All files have been downloaded and replaced")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(downloadsCompleted),
			name: Notification.Name("BatchDownloadCompleted"),
			object: nil)

		startBatchDownload()
		copyBundleFilesToDocuments()

		navigationController?.hidesBottomBarWhenPushed = false
		hidesBottomBarWhenPushed = false

		navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
		let navbarTitle = UILabel()
		navbarTitle.text = "Guide"
		navbarTitle.textColor = UIColor.white
		navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
		navbarTitle.numberOfLines = 2
		navbarTitle.textAlignment = .center
		navbarTitle.minimumScaleFactor = 0.5
		navbarTitle.adjustsFontSizeToFitWidth = true
		navigationItem.titleView = navbarTitle

		//        navigationController?.navigationItem.searchController = search

		//        let tapSearchGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearch(_:)))
		//        let tapSearchGesture2 = UITapGestureRecognizer(target: self, action: #selector(tapSearch(_:)))

		//        search.delegate = self
		//        search.searchTextField.addGestureRecognizer(tapSearchGesture)
		//        search.addGestureRecognizer(tapSearchGesture2)

		//        let textFieldInsideSearchBar = search.value(forKey: "searchField") as? UITextField
		//        textFieldInsideSearchBar?.textColor = UIColor.searchBarText
		//        textFieldInsideSearchBar?.layer.cornerRadius = 60
		//        textFieldInsideSearchBar?.backgroundColor = UIColor.searchBar
		//        textFieldInsideSearchBar?.attributedPlaceholder = NSAttributedString(string: "Search Guide",attributes: [NSAttributedString.Key.foregroundColor: UIColor.searchBarText])
		//        searchView.frame = CGRect(x: searchView.frame.origin.x, y: searchView.frame.origin.x, width: searchView.frame.width, height: search.frame.height+10)
		//
		//        navigationController?.navigationBar.setGradientBackground(to: self.navigationController!)
		//        self.navigationController?.navigationBar.shadowImage = UIImage()

		//        searchView.setGradientBackground()
		// Register for `UIContentSizeCategory.didChangeNotification`
		//        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)

		// Do any additional setup after loading the view.
	}

	// Code below is to shift the size of the view's gradient layer if the user changes Dynamic Font Size while the app is open
	//    @objc func preferredContentSizeChanged(_ notification: Notification) {
	//        print(search.frame)
	//        // Need to remove the gradient somehow and put a new gradient
	//        let newFrame = CGRect(x: searchView.frame.origin.x, y: searchView.frame.origin.x, width: searchView.frame.width, height: search.frame.height+10)
	//        searchView.removeGradientBackground()
	//        searchView.frame = newFrame
	//        searchView.setGradientBackground(size: newFrame)
	//            /* perform other operations if necessary */
	//        }

	// --------------------------------------------------------------------------------------------------
	@objc func dismissKeyboard() {
		// To hide the keyboard when the user clicks search
		view.endEditing(true)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(false)
		setupDownloadSession()
		setupNetworkMonitoring()

		//        if !isGradientAdded {
		//            searchView.setGradientBackground(size: searchView.layer.bounds)
		//            isGradientAdded = true
		//        }
		navigationController?.hidesBottomBarWhenPushed = false
		hidesBottomBarWhenPushed = false

		if scrollView == nil {
			// contentView -> scrollView -> guideView

			scrollView = UIScrollView(frame: view.frame)
			scrollView.backgroundColor = UIColor.clear
			contentView.addSubview(scrollView)
			scrollView.delaysContentTouches = true
			scrollView.translatesAutoresizingMaskIntoConstraints = false

			// Check the view (screen) height to apply appropriate spacing at the bottom to all the guideview to work
			// If the guideView is too short the bottom chart buttons are not clickable
			if view.frame.height <= 690 {
				guideView = Guide(
					frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: view.frame.height + 250)
				)
			} else if view.frame.height >= 691, view.frame.height <= 768 {
				guideView = Guide(
					frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: view.frame.height + 200)
				)
			} else if view.frame.height >= 769 {
				guideView = Guide(
					frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: view.frame.height))
			}

			scrollView.addSubview(guideView)
			scrollView.contentSize = CGSize(
				width: contentView.frame.width, height: guideView.frame.height)
			//         scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)

			NSLayoutConstraint.activate([
				scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
				scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
				scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
				scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			])

			guideView.allChapters.addTarget(
				self, action: #selector(tapAllChapters(_:)), for: .touchUpInside)
			guideView.allCharts.addTarget(
				self, action: #selector(tapAllCharts(_:)), for: .touchUpInside)
		}
	}

	private func setupNetworkMonitoring() {
		networkMonitor = NWPathMonitor()
		networkMonitor?.pathUpdateHandler = { [unowned self] path in
			self.isConnected = path.status == .satisfied
			DispatchQueue.main.async {
				// Access button directly through the outlet
				self.isConnected = path.status == .satisfied
			}
		}
		networkMonitor?.start(queue: DispatchQueue.global())
	}

	private func setupDownloadSession() {
		// Check if downloadSession is already initialized
		if downloadSession != nil {
			print("Download session already initialized: \(String(describing: downloadSession))")
			return
		}

		let configuration = URLSessionConfiguration.default
		//		configuration.timeoutIntervalForRequest = 30
		//		configuration.timeoutIntervalForResource = 300
		configuration.waitsForConnectivity = true
		configuration.allowsCellularAccess = true

		downloadSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
	}

	@IBAction func tapTopButton(_ sender: UIButton) {
		quickTitle = bible.chapters[sender.tag - 1]
		quickPointer = sender.tag - 1
		performSegue(withIdentifier: "SegueToSubChapterViewController", sender: nil)
	}

	@IBAction func tapBottomButton(_ sender: UIButton) {
		quickTitle = bible.charts[sender.tag - 1]
		quickPointer = sender.tag - 1
		performSegue(withIdentifier: "SegueToWebViewViewController", sender: nil)
	}

	@IBAction func tapAllChapters(_ sender: UIButton) {
		performSegue(withIdentifier: "SegueToAllChaptersViewController", sender: nil)
	}

	@IBAction func tapAllCharts(_ sender: UIButton) {
		performSegue(withIdentifier: "SegueToAllChartsViewController", sender: nil)
	}

	@IBAction func tapBookmarks(_ sender: UIButton) {
		performSegue(withIdentifier: "SegueToSavedViewController", sender: nil)
	}

	@IBAction func downloadFilesButton(_ sender: UIButton) {
		guard isConnected else {
			showAlert(message: "No internet connection available")
			return
		}
	}

	private func startDownload() {
		guard let url = URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf") else {
			showAlert(message: "Invalid URL")
			return
		}

		var request = URLRequest(url: url)
		request.timeoutInterval = 30
		request.cachePolicy = .reloadIgnoringLocalCacheData

		let sessionConfig = URLSessionConfiguration.default
		let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)

		let downloadTask = session.downloadTask(with: url)
		downloadTask.resume()
	}

	private func showAlert(message: String) {
		let alert = UIAlertController(title: "Download", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}

	func urlSession(
		_: URLSession, downloadTask: URLSessionDownloadTask,
		didFinishDownloadingTo location: URL
	) {
		print("Delegate method triggered. File downloaded to: \(location)")

		guard
			let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
			.first
		else {
			DispatchQueue.main.async {
				self.showAlert(message: "Could not access documents directory")
			}
			return
		}

		let destinationURL = documentsPath.appendingPathComponent("tb_coordinator.html")

		do {
			if FileManager.default.fileExists(atPath: destinationURL.path) {
				try FileManager.default.removeItem(at: destinationURL)
			}

			// Copy downloaded file to documents directory
			try FileManager.default.copyItem(at: location, to: destinationURL)

			DispatchQueue.main.async {
				self.showAlert(message: "File downloaded successfully")
			}
		} catch {
			DispatchQueue.main.async {
				self.showAlert(message: "Error saving file: \(error.localizedDescription)")
			}
		}
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let error = error {
			print("Download failed: \(error.localizedDescription)")
			showAlert(message: " \(error.localizedDescription)")
		} else {
			print("Download completed successfully.")
		}
	}

	func urlSession(
		_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
		totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
	) {
		let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
		print("Download progress: \(progress * 100)%")
	}

	deinit {
		networkMonitor?.cancel()
	}

	// --------------------------------------------------------------------------------------------------
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		navigationController?.hidesBottomBarWhenPushed = false
		hidesBottomBarWhenPushed = false

		if let guideViewController = segue.destination as? GuideViewController {
			guideViewController.hidesBottomBarWhenPushed = false
		}

		if let savedViewController = segue.destination as? SavedViewController {
			savedViewController.hidesBottomBarWhenPushed = true
		}

		if let subChapterViewController = segue.destination as? SubChapterViewController {
			subChapterViewController.arrayPointer = quickPointer
			subChapterViewController.navTitle = quickTitle
			subChapterViewController.hidesBottomBarWhenPushed = true
		}

		if let chartListViewController = segue.destination as? ChartListViewController {
			chartListViewController.arrayPointer = quickPointer
			chartListViewController.hidesBottomBarWhenPushed = true
		}

		if let contentListViewController = segue.destination as? ContentListViewController {
			contentListViewController.hidesBottomBarWhenPushed = true
		}

		if let webViewViewController = segue.destination as? WebViewViewController {
			webViewViewController.url = Bundle.main.url(
				forResource: bible.chartURLs[quickPointer], withExtension: "html")!
			webViewViewController.titlelabel = quickTitle
			webViewViewController.navTitle = "Charts"
			webViewViewController.uniqueAddress = bible.chartURLs[quickPointer]
			webViewViewController.hidesBottomBarWhenPushed = true
		}

//		if let HTMLFilesViewController = segue.destination as? HTMLFilesViewController {
//			HTMLFilesViewController.hidesBottomBarWhenPushed = true
//		}
	}
}
