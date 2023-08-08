//
//  SearchViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/28/21.
//

import UIKit
import Foundation
import FirebaseAnalytics
import Pendo

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var searchReturns: UILabel!
    var size = CGRect.init()
    
    @IBOutlet weak var tableView: UITableView!
    

    var tableViewCells: [Int : UITableViewCell] = [:]
    var subArrayPointer = 0
    var navTitle = "Placeholder SubChapter"
    var tempHTML = [String]()
    let chapterIndex = ChapterIndex()

    var searchResults = [String]()
    
    var isFiltering = false
    var searchTerm = ""
    
    var gradient : CAGradientLayer?
    let gradientView : UIView = {
        let view = UIView()
        return view
    }()
    var isGradientAdded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        let navbarTitle = UILabel()
        navbarTitle.text = "Search"
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.5
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        
        search.delegate = self
//        searchReturns.isHidden = true

        let textFieldInsideSearchBar = search.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.searchBarText
        textFieldInsideSearchBar?.attributedPlaceholder = NSAttributedString(string: "Search Guide",attributes: [NSAttributedString.Key.foregroundColor: UIColor.searchBarText])
        textFieldInsideSearchBar?.layer.cornerRadius = 60
        textFieldInsideSearchBar?.backgroundColor = UIColor.searchBar
        searchView.frame = CGRect(x: searchView.frame.origin.x, y: searchView.frame.origin.x, width: searchView.frame.width, height: search.frame.height+10)
                
        navigationController?.navigationBar.setGradientBackground(to: self.navigationController!)
        navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        // Set Gradient to the width of the navigationBar
//        searchView.setGradientBackground(size: CGRect(x: searchView.bounds.origin.x, y: searchView.bounds.origin.y, width: self.navigationController?.navigationBar.bounds.width ?? searchView.bounds.width, height: searchView.bounds.height))
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.register( UITableViewCell.self, forCellReuseIdentifier: type(of: self).description())
        tableView.register(UINib(nibName: "SearchCell", bundle: nil), forCellReuseIdentifier: "searchCell")
        tableView.rowHeight = 80
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        customView.backgroundColor = UIColor( red: 0xd5/255.0, green: 0xd8/255.0, blue: 0xdc/255.0, alpha: 1)

        let doneButton = UIButton( frame: CGRect( x: view.frame.width - 70 - 10, y: 0, width: 70, height: 44 ))
        doneButton.setTitle( "Dismiss", for: .normal )
        doneButton.setTitleColor( UIColor.systemBlue, for: .normal)
        doneButton.addTarget( self, action: #selector( self.dismissKeyboard), for: .touchUpInside )
        customView.addSubview( doneButton )
        
        search.inputAccessoryView = customView
        
        // Load the htmls on the array - needs to be on viewDidLoad otherwise it duplicates the content
        for items in chapterIndex.chapterCode.joined() {
            let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
            // This converts a multiline string into a single file, the .whitespacesandnewlines doesn't work to do that job
            var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
            tempHTML.append(htmlString)
        }
        
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))

        searchView.addGestureRecognizer(tap)
        
    }


    
    //--------------------------------------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        search.becomeFirstResponder()
        
        // Leave this for when we import from JSON and just use that order because right now it's giving me a headache
//        let fileManager = FileManager.default
//        let path = Bundle.main.resourcePath
//        
//        var tempURLs = [String]()
//
//        let enumerator:FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: "\(path!)")!
//        while let element = enumerator.nextObject() as? String {
//            if element.hasSuffix("html") { // checks the extension
//                
//                tempURLs.append(element)
//            }
//        }
//        // Need to sort arrays by numerical order before appending to new array
//        // NEED TO MOVE THIS TO ON APP LAUNCH
//        tempURLs.sort{$0.localizedStandardCompare($1) == .orderedAscending}
    }

    //--------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return searchResults.count
        } else {
            return chapterIndex.subChapterNames.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        var cell: UITableViewCell! = tableViewCells[indexPath.row]

//        cell = UITableViewCell(frame: CGRect( x: 0, y: 0, width: tableView.frame.width, height: tableView.rowHeight ))
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchCell
        cell.backgroundColor = UIColor.backgroundColor
        
        cell.accessoryType = .disclosureIndicator
        
        if isFiltering {
            cell.subchapterLabel.text = chapterIndex.subChapterNames[tempHTML.firstIndex(of: searchResults[indexPath.row]) ?? 0]
            cell.chapterLabel.text = chapterIndex.chaptermapsubchapter[tempHTML.firstIndex(of: searchResults[indexPath.row]) ?? 0]
            cell.contentLabel.isHidden = false
            
            let TSTrange = searchResults[indexPath.row].lowercased().range(of: searchTerm.lowercased())
            let startRange = searchResults[indexPath.row].index(TSTrange?.lowerBound ?? searchResults[indexPath.row].startIndex,offsetBy: -30, limitedBy: searchResults[indexPath.row].startIndex) ?? searchResults[indexPath.row].startIndex
            let endRange = searchResults[indexPath.row].index(TSTrange?.lowerBound ?? searchResults[indexPath.row].endIndex, offsetBy: 90, limitedBy: searchResults[indexPath.row].endIndex) ?? searchResults[indexPath.row].endIndex
            cell.contentLabel.text = "..."+String(searchResults[indexPath.row][startRange..<endRange]) + "..."
            let terms = searchTerm.lowercased().split(separator: " ").map({String($0) as NSString}) + [searchTerm as NSString]
            cell.contentLabel.attributedText = addBoldText(fullString: cell.contentLabel.text! as NSString, boldPartsOfString: terms)
        } else {
            // to add here the history searches from the past - need Realm queries
            cell.subchapterLabel.text = chapterIndex.subChapterNames[indexPath.row]
            cell.chapterLabel.text = chapterIndex.chaptermapsubchapter[indexPath.row]
            cell.contentLabel.isHidden = true
        }
        cell.subchapterLabel.lineBreakMode = .byTruncatingTail
        cell.subchapterLabel.numberOfLines = 2
        cell.chapterLabel.numberOfLines = 2
        
//        tableViewCells[indexPath.row] = cell
            
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if self.search.isFirstResponder {
            self.search.endEditing(true)
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        
        // Need to add logic to insert table view or html content based on what was clicked
        // The first index is screwing me because there are multiple chapters with the same title i.e. considerations, or introduction, so it messes up the algorithm
        if isFiltering {
            subArrayPointer = tempHTML.firstIndex(of: searchResults[indexPath.row]) ?? 0
        } else {
            // to add here the history searches from the past
            subArrayPointer = indexPath.row
        }
        
        navTitle = chapterIndex.chaptermapsubchapter[indexPath.row]
        
        Analytics.logEvent("search", parameters: [
            "search": (searchTerm ) as String,
        ])
        
        PendoManager.shared().track("search", properties: ["searchTerm":searchTerm, "selectedResult":chapterIndex.subChapterNames[indexPath.row]])
        
        performSegue( withIdentifier: "SegueToWebViewViewController", sender: nil )
    }
    
    //--------------------------------------------------------------------------------------------------
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        if searchText != ""{
            // Could be search always the strings independently or could be to first search strings together and if nothing returns then search the terms separately but giving the user the option to do that
            if searchText.components(separatedBy: " ").count > 1 {
                let doubleString = searchText.components(separatedBy: " ")
                searchResults = tempHTML
                for i in 0...doubleString.count-1 {
                    // This statement is to prevent a 0 return from the "" generated when a space is introduced
                    if doubleString[i] != ""{
                        searchResults = searchResults.filter { $0.lowercased().contains(doubleString[i].lowercased())}
                    }
                }
                searchTerm = searchText
            } else {
                searchResults = tempHTML.filter { $0.lowercased().contains(searchText.lowercased())}
                searchTerm = searchText
            }
            isFiltering = true
        } else {
            isFiltering = false
            searchResults = [String]()
        }
//        searchReturns.isHidden = false
        searchReturns.text = String(searchResults.count) + " results"
        
        tableView.reloadData()
    }

    

    //--------------------------------------------------------------------------------------------------
    // To hide the keyboard when the user clicks search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        Analytics.logEvent("search", parameters: [
            "query": (searchTerm ) as String,
        ])
    }
    
    //--------------------------------------------------------------------------------------------------
    @objc func dismissKeyboard() {
        // To hide the keyboard when the user clicks search
        self.view.endEditing(true)
        Analytics.logEvent("search", parameters: [
            "query": (searchTerm ) as String,
        ])
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let webViewViewController = segue.destination as? WebViewViewController
        {
            webViewViewController.url = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[subArrayPointer], withExtension: "html")!
            webViewViewController.titlelabel = Array(chapterIndex.chapterNested.joined())[subArrayPointer]
            webViewViewController.navTitle = navTitle
            webViewViewController.comingFromSearch = true
            webViewViewController.searchTerm = search.text
            webViewViewController.uniqueAddress = Array(chapterIndex.chapterCode.joined())[subArrayPointer]
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    // Bolding function from online - https://exceptionshub.com/making-text-bold-using-attributed-string-in-swift.html
    func addBoldText(fullString: NSString, boldPartsOfString: Array<NSString>) -> NSAttributedString {
        let nonBoldFontAttribute = [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 12)]
        let boldString = NSMutableAttributedString(string: fullString as String, attributes:nonBoldFontAttribute)
        let lowercase = fullString.lowercased as NSString
        for i in 0 ..< boldPartsOfString.count {
            boldString.addAttribute(.backgroundColor, value: UIColor.yellow, range: lowercase.range(of: boldPartsOfString[i] as String))
            boldString.addAttribute(.foregroundColor, value: UIColor.black, range: lowercase.range(of: boldPartsOfString[i] as String))
        }
        return boldString
    }
}
