//
//  GuideViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit
import RealmSwift
import FirebaseDynamicLinks
import Network

class GuideViewController: UIViewController, URLSessionDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStackView: UIStackView!
    
    var guideView: Guide!
    var url: URL!
    var header: String!

	private var downloadTask: URLSessionDownloadTask!
	private var downloadSession: URLSession!
	private var networkMonitor: NWPathMonitor?
	private var isConnected = true

    var quickTitle = ""
    var quickPointer = 0
    
    let bible = ChapterIndex()
    
    var isGradientAdded: Bool = false

	let remoteConfig = RemoteConfigHelper()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.hidesBottomBarWhenPushed = false
        self.hidesBottomBarWhenPushed = false
        
        if #available(iOS 26.0, *) {
            tabBarController?.tabBar.backgroundColor = .clear
        } else {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            appearance.backgroundColor = .colorBackgroundSecondary
            
            tabBarController?.tabBar.standardAppearance = appearance
            
            if #available(iOS 15.0, *) {
                tabBarController?.tabBar.scrollEdgeAppearance = appearance
            }
        }
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        let navbarTitle = UILabel()
        navbarTitle.text = "Guide"
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.7
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        navigationItem.backButtonDisplayMode = .minimal
        
        guideView = Guide()
        
        guideView.translatesAutoresizingMaskIntoConstraints = false
        
        guideView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        contentStackView.isUserInteractionEnabled = true
        
        guard let stackView = contentStackView else {
            print("ERROR: contentStackView is nil")
            return
        }
        
        guard let guide = guideView else {
            print("ERROR: guideView is nil")
            return
        }
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.addArrangedSubview(guide)
        
        let frameHeight: CGFloat

        frameHeight = view.frame.height
            
        NSLayoutConstraint.activate([
            guideView.heightAnchor.constraint(equalToConstant: frameHeight),
            guideView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor)
        ])
        
        view.layoutIfNeeded()
        
        guard let allChaptersButton = guide.allChapters else {
            print("ERROR: guideView.allChapters is nil")
            return
        }
        
        guard let allChartsButton = guide.allCharts else {
            print("ERROR: guideView.allCharts is nil")
            return
        }
        
        allChaptersButton.addTarget(self, action: #selector(self.tapAllChapters(_:)), for: .touchUpInside)
        allChartsButton.addTarget(self, action: #selector(self.tapAllCharts(_:)), for: .touchUpInside)
        
        // Do any additional setup after loading the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.preloadKeyboard()
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        setupDownloadSession()
        setupNetworkMonitoring()
        
        remoteConfig.configureRemoteConfig()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(downloadsCompleted),
            name: Notification.Name("BatchDownloadCompleted"),
            object: nil)
        
        navigationController?.hidesBottomBarWhenPushed = false
        self.hidesBottomBarWhenPushed = false
    }

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(true)
		print("NOTIFICATIONCENTER DISAPPEARED")
		NotificationCenter.default.removeObserver(self, name: Notification.Name("BatchDownloadCompleted"), object: nil)
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
		configuration.waitsForConnectivity = true
		configuration.allowsCellularAccess = true

		downloadSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
	}

	@objc func downloadsCompleted(_ notification: Notification) {
		let alertTitle: String = "New Content Available"
		let alertMessage: String = "Fresh updates are ready for you to continue enjoying the app."

		if let updatedFiles = notification.userInfo?["updatedFiles"] as? [String] {
			print("Updated files: \(updatedFiles)")
			DispatchQueue.main.async {
				self.showAlert(title: alertTitle, message: alertMessage)
			}
		} else {
			print("No updated files info.")
			DispatchQueue.main.async {
				self.showAlert(title: alertTitle, message: alertMessage)
			}
		}
	}


	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}
    
    // This is to remove the keyboard lag/delay when the app has just been launched for the first time
    private func preloadKeyboard() {
        let tempTextField = UITextField()
        view.addSubview(tempTextField)
        tempTextField.becomeFirstResponder()
        tempTextField.resignFirstResponder()
        tempTextField.removeFromSuperview()
    }

    
    @IBAction func tapTopButton(_ sender: UIButton){
        quickTitle = bible.chapters[sender.tag]
        quickPointer = sender.tag
        performSegue( withIdentifier: "SegueToSubChapterViewController", sender: nil )
    }
    
    @IBAction func tapBottomButton(_ sender: UIButton){
        quickTitle = bible.chartsTrimmed[sender.tag-1]
        quickPointer = sender.tag-1
        performSegue( withIdentifier: "SegueToWebViewViewController", sender: nil )
    }
    
    @IBAction func tapAllChapters(_ sender: UIButton){
        performSegue(withIdentifier: "SegueToAllChaptersViewController", sender: nil)
    }
    
    @IBAction func tapAllCharts(_ sender: UIButton){
        performSegue(withIdentifier: "SegueToAllChartsViewController", sender: nil)
    }
    
    @IBAction func tapBookmarks(_ sender: UIButton){
        performSegue(withIdentifier: "SegueToSavedViewController", sender: nil)
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        navigationController?.hidesBottomBarWhenPushed = false
        self.hidesBottomBarWhenPushed = false
        
        if let guideViewController = segue.destination as? GuideViewController
        {
            guideViewController.hidesBottomBarWhenPushed = false
        }
        
        if let savedViewController = segue.destination as? SavedViewController
        {
            savedViewController.hidesBottomBarWhenPushed = true
        }
        
        if let subChapterViewController = segue.destination as? SubChapterViewController
        {
            subChapterViewController.arrayPointer = quickPointer
            subChapterViewController.navTitle = quickTitle
            subChapterViewController.hidesBottomBarWhenPushed = true
        }
        
        if let chartListViewController = segue.destination as? ChartListViewController
        {
            chartListViewController.arrayPointer = quickPointer
            chartListViewController.hidesBottomBarWhenPushed = true
        }
        
        if let contentListViewController = segue.destination as? ContentListViewController {
            contentListViewController.hidesBottomBarWhenPushed = true
        }
        
        if let webViewViewController = segue.destination as? WebViewViewController
        {
            webViewViewController.url = Bundle.main.url(forResource: bible.chartURLs[quickPointer], withExtension: "html")!
            webViewViewController.titlelabel = quickTitle
            webViewViewController.navTitle = quickTitle
            webViewViewController.uniqueAddress = bible.chartURLs[quickPointer]
            webViewViewController.hidesBottomBarWhenPushed = true
        }
    }
}
