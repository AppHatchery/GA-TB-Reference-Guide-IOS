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

    @IBOutlet var topQuickLinks: [UIButton]!
    @IBOutlet var bottomQuickLinks: [UIButton]!
    @IBOutlet weak var contentView: UIView!

    var scrollView: UIScrollView!
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
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        let navbarTitle = UILabel()
        navbarTitle.text = "Guide"
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.5
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        
        // Do any additional setup after loading the view
    }
    
    //--------------------------------------------------------------------------------------------------
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)

		remoteConfig.configureRemoteConfig()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(downloadsCompleted),
			name: Notification.Name("BatchDownloadCompleted"),
			object: nil)
	}

    override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(true)

		setupDownloadSession()
		setupNetworkMonitoring()

		remoteConfig.configureRemoteConfig()

        navigationController?.hidesBottomBarWhenPushed = false
        self.hidesBottomBarWhenPushed = false
        
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
                guideView = Guide(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: view.frame.height + 250))
            } else if view.frame.height >= 691 && view.frame.height <= 768 {
                guideView = Guide(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: view.frame.height + 200))
            } else if view.frame.height >= 769 {
                guideView = Guide(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: view.frame.height))
            }
            
            scrollView.addSubview(guideView)
            scrollView.contentSize = CGSize(width: contentView.frame.width, height: guideView.frame.height)
//         scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 200, right: 0)
            
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
            
            guideView.allChapters.addTarget( self, action: #selector( self.tapAllChapters( _:)), for: .touchUpInside)
            guideView.allCharts.addTarget( self, action: #selector( self.tapAllCharts( _:)), for: .touchUpInside)
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
		configuration.waitsForConnectivity = true
		configuration.allowsCellularAccess = true

		downloadSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
	}

	@objc func downloadsCompleted(_ notification: Notification) {
		let alertTitle: String = "New Content Available"
		let alertMessage: String = "Fresh updates are ready for you to continue enjoying the app."

		if let userInfo = notification.userInfo as? [String: Any],
		   let updatedFiles = userInfo["updatedFiles"] as? [String] {

			DispatchQueue.main.async {
				self.showAlert(title: alertTitle, message: alertMessage)
			}
		} else {
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

    
    @IBAction func tapTopButton(_ sender: UIButton){
        quickTitle = bible.chapters[sender.tag-1]
        quickPointer = sender.tag-1
        performSegue( withIdentifier: "SegueToSubChapterViewController", sender: nil )
    }
    
    @IBAction func tapBottomButton(_ sender: UIButton){
        quickTitle = bible.charts[sender.tag-1]
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
            webViewViewController.navTitle = "Charts"
            webViewViewController.uniqueAddress = bible.chartURLs[quickPointer]
            webViewViewController.hidesBottomBarWhenPushed = true
        }
    }
}
