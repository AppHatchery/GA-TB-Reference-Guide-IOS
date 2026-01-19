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
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register( UITableViewCell.self, forCellReuseIdentifier: type(of: self).description())
        tableView.estimatedRowHeight = 80
        tableView.estimatedRowHeight = UITableView.automaticDimension
		tableView.separatorStyle = .none
		tableView.backgroundColor = .backgroundColor
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavBar()
    }
    
    func setupNavBar() {
        navigationController?.navigationBar.tintColor = .white
        navigationItem.backButtonDisplayMode = .minimal
        
        let titleLabel = UILabel()
        titleLabel.text = navTitle
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        
        if #available(iOS 26.0, *) {
            titleLabel.sizeToFit()
        } else {
            let maxWidth = UIScreen.main.bounds.width - 120
            let size = titleLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
            titleLabel.frame = CGRect(origin: .zero, size: size)
        }
        
        navigationItem.titleView = titleLabel
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
            cell.textLabel?.font = .systemFont(ofSize: 15)
            
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

