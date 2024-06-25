//
//  GuideViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit
import RealmSwift
import FirebaseDynamicLinks

class GuideViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet var topQuickLinks: [UIButton]!
    @IBOutlet var bottomQuickLinks: [UIButton]!
    
//    @IBOutlet weak var searchView: UIView!
//    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var contentView: UIView!
    var scrollView: UIScrollView!
    var guideView: Guide!
    var url: URL!
    var header: String!
    
    var quickTitle = ""
    var quickPointer = 0
    
    let bible = ChapterIndex()
    
    var isGradientAdded: Bool = false
    
//    var search = UISearchController(searchResultsController: nil) // Declare the searchController
        
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

    
    //--------------------------------------------------------------------------------------------------
    @objc func dismissKeyboard() {
        // To hide the keyboard when the user clicks search
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
//        if !isGradientAdded {
//            searchView.setGradientBackground(size: searchView.layer.bounds)
//            isGradientAdded = true
//        }
        navigationController?.hidesBottomBarWhenPushed = false
        self.hidesBottomBarWhenPushed = false
        
        if scrollView == nil {
            
            scrollView = UIScrollView( frame: view.frame )
            scrollView.backgroundColor = UIColor.clear
            contentView.addSubview( scrollView )
            scrollView.delaysContentTouches = false
                    
            guideView = Guide(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
            scrollView.addSubview(guideView)
                    
            scrollView.contentSize = CGSize(width: contentView.frame.width, height: 700)

            guideView.allChapters.addTarget( self, action: #selector( self.tapAllChapters( _:)), for: .touchUpInside )
            guideView.allCharts.addTarget( self, action: #selector( self.tapAllCharts( _:)), for: .touchUpInside )
        }
    }
    
//    @objc func tapSearch(_ sender: UITapGestureRecognizer){
//        print("tapped search")
//        performSegue(withIdentifier: "SegueToSearchViewController", sender: nil)
//    }
    
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
        

//        if let searchViewController = segue.destination as? SearchViewController
//        {
//            searchViewController.size = searchView.bounds
//        }
    }
}
