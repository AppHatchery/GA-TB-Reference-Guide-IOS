//
//  GuideViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit

class GuideViewController: UIViewController, UISearchBarDelegate {

    @IBOutlet var topQuickLinks: [UIButton]!
    @IBOutlet var bottomQuickLinks: [UIButton]!
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var search: UISearchBar!
    
    var url: URL!
    var header: String!
    
    var quickTitle = ""
    var quickPointer = 0
    
    let bible = ChapterIndex()
    
    var isGradientAdded: Bool = false
    
//    var search = UISearchController(searchResultsController: nil) // Declare the searchController
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
//        navigationController?.navigationItem.searchController = search
        
        let tapSearchGesture = UITapGestureRecognizer(target: self, action: #selector(tapSearch(_:)))
        let tapSearchGesture2 = UITapGestureRecognizer(target: self, action: #selector(tapSearch(_:)))
        
        search.delegate = self
        search.searchTextField.addGestureRecognizer(tapSearchGesture)
        search.addGestureRecognizer(tapSearchGesture2)

        let textFieldInsideSearchBar = search.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.darkGray
        textFieldInsideSearchBar?.layer.cornerRadius = 60
        textFieldInsideSearchBar?.backgroundColor = UIColor.init(white: 255/255, alpha: 1.0)
                
        navigationController?.navigationBar.setGradientBackground(to: self.navigationController!)
        navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
//        searchView.setGradientBackground()
        
        for button in topQuickLinks {
            button.layer.cornerRadius = 5
            button.dropShadow()
        }
        
        for button in bottomQuickLinks {
            button.layer.cornerRadius = 5
            button.titleLabel?.textAlignment = NSTextAlignment.center
            button.dropShadow()
        }
        
        // Do any additional setup after loading the view.
    }
    
    //--------------------------------------------------------------------------------------------------
    @objc func dismissKeyboard() {
        // To hide the keyboard when the user clicks search
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        if !isGradientAdded {
            searchView.setGradientBackground(size: searchView.layer.bounds)
            isGradientAdded = true
        }
    }
    
    @objc func tapSearch(_ sender: UITapGestureRecognizer){
        print("tapped search")
        performSegue(withIdentifier: "SegueToSearchViewController", sender: nil)
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
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let subChapterViewController = segue.destination as? SubChapterViewController
        {
            subChapterViewController.arrayPointer = quickPointer
            subChapterViewController.navTitle = quickTitle
        }
        
        if let chartListViewController = segue.destination as? ChartListViewController
        {
            chartListViewController.arrayPointer = quickPointer
        }
        
        if let webViewViewController = segue.destination as? WebViewViewController
        {
            webViewViewController.url = Bundle.main.url(forResource: bible.chartURLs[quickPointer], withExtension: "html")!
            webViewViewController.titlelabel = quickTitle
            webViewViewController.navTitle = "Charts"
            webViewViewController.uniqueAddress = bible.chartURLs[quickPointer]
        }
        
        if let searchViewController = segue.destination as? SearchViewController
        {
            searchViewController.size = searchView.bounds
        }
    }
}
