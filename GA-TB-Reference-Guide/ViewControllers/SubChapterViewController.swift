//
//  SubChapterViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit

class SubChapterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    var tableViewCells: [Int : UITableViewCell] = [:]
    
    var arrayPointer = 0
    var subArrayPointer = 0
    var navTitle = ""
            
    let chapterIndex = ChapterIndex()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navbarTitle = UILabel()
        navbarTitle.text = navTitle
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.5
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
//        self.title = navTitle
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapGlobalSearch))
//        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register( UITableViewCell.self, forCellReuseIdentifier: type(of: self).description())
        tableView.estimatedRowHeight = 80
        tableView.estimatedRowHeight = UITableView.automaticDimension
        // Do any additional setup after loading the view.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chapterIndex.chapterNested[arrayPointer].count
    }
    
    private func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell! = tableViewCells[indexPath.row]
        
        if cell != nil
        {
            return cell
        }
        else
        {
            cell = UITableViewCell(frame: CGRect( x: 0, y: 0, width: tableView.frame.width, height: tableView.rowHeight ))
            
            cell.accessoryType = .disclosureIndicator
            
            cell.textLabel?.text = chapterIndex.chapterNested[arrayPointer][indexPath.row]
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.numberOfLines = 6
            
            tableViewCells[indexPath.row] = cell
            
        }
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Need to add logic to insert table view or html content based on what was clicked
        
        
//        let urlstring = chapterIndex.chapterCode[chapterIndex.chapterTitle.firstIndex(of: tableViewCells[indexPath.row]?.textLabel?.text ?? "") ?? 0]
//        print("This is the string for the url",urlstring)
//        subChapterURL = Bundle.main.url(forResource: urlstring, withExtension: "html")!
        subArrayPointer = indexPath.row
        
        performSegue( withIdentifier: "SegueToWebViewViewController", sender: nil )
    }
    
    //--------------------------------------------------------------------------------------------------
    @objc func tapGlobalSearch(){
        performSegue( withIdentifier: "SegueToSearchViewController", sender: nil )
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let webViewViewController = segue.destination as? WebViewViewController
        {
            webViewViewController.url = Bundle.main.url(forResource: chapterIndex.chapterCode[arrayPointer][subArrayPointer], withExtension: "html")!
            webViewViewController.titlelabel = chapterIndex.chapterNested[arrayPointer][subArrayPointer]
            webViewViewController.navTitle = navTitle
            webViewViewController.uniqueAddress = chapterIndex.chapterCode[arrayPointer][subArrayPointer]
        }
        
        if let searchViewController = segue.destination as? SearchViewController
        {
            searchViewController.size = CGRect.init(x: 0, y: 0, width: view.frame.width, height: 60)
        }
    }
}
