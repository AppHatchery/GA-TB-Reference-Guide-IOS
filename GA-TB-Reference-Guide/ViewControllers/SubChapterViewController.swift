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
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(true)
        
        let navbarTitle = UILabel()
        navbarTitle.text = navTitle
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.7
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        navigationItem.backButtonDisplayMode = .minimal
        
        let navBarWidth = navigationController?.navigationBar.bounds.width ?? UIScreen.main.bounds.width
        navbarTitle.frame = CGRect(x: 0, y: 0, width: navBarWidth - 100, height: 44)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register( UITableViewCell.self, forCellReuseIdentifier: type(of: self).description())
        tableView.estimatedRowHeight = 80
        tableView.estimatedRowHeight = UITableView.automaticDimension
		tableView.separatorStyle = .none
		tableView.backgroundColor = .backgroundColor
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
            cell.backgroundColor = .colorBackgroundSecondary
			cell.textLabel?.textColor = .colorTextDarker

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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let webViewViewController = segue.destination as? WebViewViewController
        {
				// The second condition in the if statement: chapterIndex.chapterCode[arrayPointer][subArrayPointer] ==  "15_appendix_district_tb_coordinators_(by_district)"
				// is to ensure that the chapterIndex matches the file name that needs rerouting,
				// if not included, every file url routes to TB Coordinators table
			if isFileDownloaded(for: chapterIndex
				.chapterCode[arrayPointer][subArrayPointer]) && chapterIndex
				.chapterCode[arrayPointer][subArrayPointer] ==  "15_appendix_district_tb_coordinators_(by_district)" {
				webViewViewController.url = getFileURL(for: chapterIndex.chapterCode[arrayPointer][subArrayPointer])
			} else {
				webViewViewController.url = Bundle.main.url(forResource: chapterIndex.chapterCode[arrayPointer][subArrayPointer], withExtension: "html")!
			}
			
            webViewViewController.titlelabel = chapterIndex.chapterNested[arrayPointer][subArrayPointer]
            webViewViewController.navTitle = chapterIndex.chapterNested[arrayPointer][subArrayPointer]
            webViewViewController.uniqueAddress = chapterIndex.chapterCode[arrayPointer][subArrayPointer]
        }
    }
}
