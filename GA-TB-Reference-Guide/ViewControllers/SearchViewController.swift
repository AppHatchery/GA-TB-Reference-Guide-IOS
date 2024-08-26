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
    @IBOutlet weak var searchSuggestionsTableView: UITableView!
    @IBOutlet weak var recentSearchesTableView: UITableView!
    @IBOutlet weak var mainTableView: UIView!
    @IBOutlet weak var suggestionsView: UIView!
    @IBOutlet weak var recentSearchesView: UIView!
    @IBOutlet weak var searchSuggestionsView: UIView!
    @IBOutlet weak var allChaptersChartsButton: UIButton!
    @IBOutlet weak var chaptersButton: UIButton!
    @IBOutlet weak var chartsButton: UIButton!
    
    @IBOutlet var searchTabs: [UIButton]!
    
    
    // Initialize Realm
    let realm = RealmHelper.sharedInstance.mainRealm()
    
    var tableViewCells: [Int : UITableViewCell] = [:]
    var subArrayPointer = 0
    var navTitle = "Placeholder SubChapter"
    var tempHTML = [String]()
	var tempChartHTML = [String]()
    let chapterIndex = ChapterIndex()

    var searchResults = [String]()
	var chapterResults = [String]()
	var chartResults = [String]()
	var searchResultCache = [String]()
    
    var isFiltering = false
    var searchTerm = ""
    
    var gradient : CAGradientLayer?
    let gradientView : UIView = {
        let view = UIView()
        return view
    }()
    var isGradientAdded: Bool = false
    
    let tap = UITapGestureRecognizer()
    
    let suggestionsList: Array = ["Regimens", "Pregnancy", "Rifampin"]
    var recentSearchesList: Array = [String]()
	
	var showAll: Bool = true
	var showChapters: Bool = false
	var showCharts: Bool = false
    
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
        
        for searchTab in searchTabs {
            searchTab.layer.cornerRadius = 5
        }
        
        loadHTML()
        
        setupMainTableView()
        setupSearchSuggestionTableView()
        setupRecentSearchesTableView()
        
        // Load the Suggestions Table first before the the Main Table
        showSuggestions()
        
        // Keyboard dismissal recognizer
        tap.addTarget(self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func loadHTML() {
        // Load the htmls on the array - needs to be on viewDidLoad otherwise it duplicates the content
        for items in chapterIndex.chapterCode.joined() {
            let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
            // This converts a multiline string into a single file, the .whitespacesandnewlines doesn't work to do that job
            var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
            tempHTML.append(htmlString)
        }
		
		for items in chapterIndex.chartCode.joined() {
			let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
				// This converts a multiline string into a single file, the .whitespacesandnewlines doesn't work to do that job
			var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
			htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
			tempChartHTML.append(htmlString)
		}
    }
    
    private func setupMainTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "SearchCell", bundle: nil), forCellReuseIdentifier: "searchCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 45
    }

    private func setupSearchSuggestionTableView() {
        searchSuggestionsTableView.delegate = self
        searchSuggestionsTableView.dataSource = self
        searchSuggestionsTableView.register(UINib(nibName: "SuggestionTableViewCell", bundle: nil), forCellReuseIdentifier: "suggestionCell")
    }
    
    private func setupRecentSearchesTableView() {
        recentSearchesTableView.delegate = self
        recentSearchesTableView.dataSource = self
        recentSearchesTableView.register(UINib(nibName: "RecentSearchTableViewCell", bundle: nil), forCellReuseIdentifier: "recentSearchCell")
        recentSearchesTableView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    func showTableView() {
        suggestionsView.isHidden = true
        mainTableView.isHidden = false
        searchReturns.isHidden = false
        
        if searchTerm == "" {
            search.becomeFirstResponder()
        }
        
        self.allChaptersChartsButton.addTarget(self, action: #selector(showAllChapters), for: .touchUpInside)
        self.chaptersButton.addTarget(self, action: #selector(showChaptersOnly), for: .touchUpInside)
        self.chartsButton.addTarget(self, action: #selector(showChartsOnly), for: .touchUpInside)
    }
    
	
	//----------------------------------------------------------------------------------------------
	// Search Tabs Implementation
	
	private func activeTabConfig(
		_ button: UIButton, backgroundColor: UIColor, tintColor: UIColor, isEnabled: Bool = true
	) {
		button.backgroundColor = backgroundColor
		button.tintColor = tintColor
		button.isEnabled = isEnabled
	}
	
	@objc private func showAllChapters() {
		activeTabConfig(allChaptersChartsButton, backgroundColor: .dialogColor, tintColor: .white)
		activeTabConfig(chaptersButton, backgroundColor: .backgroundColor, tintColor: .label)
		activeTabConfig(chartsButton, backgroundColor: .backgroundColor, tintColor: .label)
		
		showAll = true
		showChapters = false
		showCharts = false
		
		searchResults = searchResultCache
		tableView.reloadData()
		
		if showAll {
			searchReturns.text = String(searchResults.count) + " results in"
		}
	}
	
	@objc private func showChaptersOnly() {
		activeTabConfig(chaptersButton, backgroundColor: .dialogColor, tintColor: .white)
		activeTabConfig(allChaptersChartsButton, backgroundColor: .backgroundColor, tintColor: .label)
		activeTabConfig(chartsButton, backgroundColor: .backgroundColor, tintColor: .label)
		showAll = false
		showChapters = true
		showCharts = false
		
		searchResults = chapterResults
		tableView.reloadData()
		
		if showChapters {
			searchReturns.text = String(chapterResults.count) + " results in"
		}
	}
	
	@objc private func showChartsOnly() {
		activeTabConfig(chartsButton, backgroundColor: .dialogColor, tintColor: .white)
		activeTabConfig(allChaptersChartsButton, backgroundColor: .backgroundColor, tintColor: .label)
		activeTabConfig(chaptersButton, backgroundColor: .backgroundColor, tintColor: .label)
		
		showAll = false
		showChapters = false
		showCharts = true
		
		searchResults = chartResults
		tableView.reloadData()
		
		if showCharts {
			searchReturns.text = String(chartResults.count) + " results in"
		}
	}
    
    func showSuggestions() {
        recentSearchesList = getRecentSearches()
        
        mainTableView.isHidden = true
        suggestionsView.isHidden = false
        searchReturns.isHidden = true
        
        searchReturns.text = "You may want to search for"
        
        if recentSearchesList.count == 0 {
            recentSearchesView.isHidden = true
        } else {
            recentSearchesView.isHidden = false
        }
    }
    
    func getRecentSearchesObjects() -> [Search] {
        // Fetch all recent searches from Realm
        let recentSearches = realm!.objects(Search.self)
        
        // Convert to an array of Search objects
        return Array(recentSearches)
    }
    
    func getRecentSearches() -> [String] {
        // Fetch all recent searches from Realm
        let recentSearches = realm!.objects(Search.self)
        
        // Convert to an array of strings and reverse
        return Array(recentSearches.map { $0.recentSearch }).reversed()
    }
	
	func filterResults() -> [String] {
		let filteredSubChapterNames = chapterIndex.subChapterNames.filter { subChapter in
			let regex = try! NSRegularExpression(pattern: "^Table \\d+:\\s*", options: [])
			let range = NSRange(location: 0, length: subChapter.utf16.count)
			return regex.firstMatch(in: subChapter, options: [], range: range) != nil
		}
		
		return filteredSubChapterNames
	}
    
    //--------------------------------------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView != self.tableView {
            let rowHeight: CGFloat = 24
            let gapHeight: CGFloat = 12
            return rowHeight + gapHeight
        }
        return 80
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recentSearchesList = getRecentSearches()
//		chartResults = filterResults()
        
        if tableView == self.tableView {
            if isFiltering {
				if showCharts {
					let commonValues = chartResults.filter { searchResults.contains($0) }
					
					print("CHART COUNT::::::::::::::: \(chartResults.count)")
					return chartResults.count
				} else {
					return searchResults.count
				}
            } else {
                return chapterIndex.subChapterNames.count
            }
        } else if tableView == self.searchSuggestionsTableView {
            return suggestionsList.count
        } else {
            return recentSearchesList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        recentSearchesList = getRecentSearches()
		let subChartNames = filterResults()
        
        if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchCell
            cell.backgroundColor = UIColor.backgroundColor
            
            cell.accessoryType = .disclosureIndicator
            
            if isFiltering {
				if showCharts {
					
					let subchapterNameIndex = tempChartHTML.firstIndex(of: chartResults[indexPath.row]) ?? 0
//					print(chartResults[subchapterNameIndex])
				
					cell.subchapterLabel.text = subChartNames[subchapterNameIndex]
					cell.chapterLabel.text = chapterIndex.chartmapsubchapter[subchapterNameIndex]
					cell.contentLabel.isHidden = false
					
					let TSTrange = chartResults[indexPath.row].lowercased().range(of: searchTerm.lowercased())
					let startRange = chartResults[indexPath.row].index(TSTrange?.lowerBound ?? chartResults[indexPath.row].startIndex, offsetBy: -30, limitedBy: chartResults[indexPath.row].startIndex) ?? chartResults[indexPath.row].startIndex
					let endRange = chartResults[indexPath.row].index(TSTrange?.lowerBound ?? chartResults[indexPath.row].endIndex, offsetBy: 90, limitedBy: chartResults[indexPath.row].endIndex) ?? chartResults[indexPath.row].endIndex
					cell.contentLabel.text = "..." + String(chartResults[indexPath.row][startRange..<endRange]) + "..."
					let terms = searchTerm.lowercased().split(separator: " ").map({ String($0) as NSString }) + [searchTerm as NSString]
					cell.contentLabel.attributedText = addBoldText(fullString: cell.contentLabel.text! as NSString, boldPartsOfString: terms)
				} else {
					let subchapterNameIndex = tempHTML.firstIndex(of: searchResults[indexPath.row]) ?? 0

					cell.subchapterLabel.text = chapterIndex.subChapterNames[subchapterNameIndex]
					cell.chapterLabel.text = chapterIndex.chaptermapsubchapter[subchapterNameIndex]
					cell.contentLabel.isHidden = false
					
					let TSTrange = searchResults[indexPath.row].lowercased().range(of: searchTerm.lowercased())
					let startRange = searchResults[indexPath.row].index(TSTrange?.lowerBound ?? searchResults[indexPath.row].startIndex, offsetBy: -30, limitedBy: searchResults[indexPath.row].startIndex) ?? searchResults[indexPath.row].startIndex
					let endRange = searchResults[indexPath.row].index(TSTrange?.lowerBound ?? searchResults[indexPath.row].endIndex, offsetBy: 90, limitedBy: searchResults[indexPath.row].endIndex) ?? searchResults[indexPath.row].endIndex
					cell.contentLabel.text = "..." + String(searchResults[indexPath.row][startRange..<endRange]) + "..."
					let terms = searchTerm.lowercased().split(separator: " ").map({ String($0) as NSString }) + [searchTerm as NSString]
					cell.contentLabel.attributedText = addBoldText(fullString: cell.contentLabel.text! as NSString, boldPartsOfString: terms)
				}
            } else {
                cell.subchapterLabel.text = chapterIndex.subChapterNames[indexPath.row]
                cell.chapterLabel.text = chapterIndex.chaptermapsubchapter[indexPath.row]
                cell.contentLabel.isHidden = true
            }

            
            cell.subchapterLabel.lineBreakMode = .byTruncatingTail
            cell.subchapterLabel.numberOfLines = 2
            cell.chapterLabel.numberOfLines = 2
            
            return cell
        } else if tableView == self.searchSuggestionsTableView {
            let suggestionCell = tableView.dequeueReusableCell(withIdentifier: "suggestionCell", for: indexPath) as! SuggestionTableViewCell
            suggestionCell.backgroundColor = UIColor.backgroundColor
            suggestionCell.suggestionLabel.text = suggestionsList[indexPath.row]
            
            return suggestionCell
        } else {
            let recentSearchCell = tableView.dequeueReusableCell(withIdentifier: "recentSearchCell", for: indexPath) as! RecentSearchTableViewCell
            recentSearchCell.backgroundColor = UIColor.backgroundColor
            recentSearchCell.recentSearchLabel.text = recentSearchesList[indexPath.row]
            
            return recentSearchCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.tableView {
            if isFiltering {
				showCharts ? (subArrayPointer = tempChartHTML.firstIndex(of: chartResults[indexPath.row]) ?? 0) : (subArrayPointer = tempHTML.firstIndex(of: searchResults[indexPath.row]) ?? 0)
            } else {
                subArrayPointer = indexPath.row
            }
            
			navTitle = showCharts ? chapterIndex.chaptermapsubchapter[indexPath.row] : chapterIndex.chaptermapsubchapter[indexPath.row]
		
            addRecentSearch(searchTerm: searchTerm)

            // Analytics and tracking code
            Analytics.logEvent("search", parameters: [
                "search": (searchTerm) as String,
            ])
            
            PendoManager.shared().track("search", properties: ["searchTerm": searchTerm, "selectedResult": chapterIndex.subChapterNames[indexPath.row]])
            
            performSegue(withIdentifier: "SegueToWebViewViewController", sender: nil)
        } else if tableView == self.searchSuggestionsTableView {
            search.text = suggestionsList[indexPath.row]
            searchTerm = suggestionsList[indexPath.row]
            searchBar(search, textDidChange: searchTerm)
            
            addRecentSearch(searchTerm: searchTerm)
        } else {
            search.text = recentSearchesList[indexPath.row]
            searchTerm = recentSearchesList[indexPath.row]
            
            searchBar(search, textDidChange: searchTerm)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Function to add a recent search term
    func addRecentSearch(searchTerm: String) {
        if searchTerm.count >= 2 {
            if realm?.object(ofType: Search.self, forPrimaryKey: searchTerm) == nil {
                let recentSearch = Search()
                let recentSearchObjects = getRecentSearchesObjects()
                var recentSearchesList = getRecentSearches()
                
                recentSearch.recentSearch = searchTerm
                
                try! realm!.write {
                    // If there are more than 4 recent searches, remove the oldest one
                    if recentSearchObjects.count >= 3 {
                        if let firstRecentSearch = recentSearchObjects.first {
                            realm?.delete(firstRecentSearch)
                            recentSearchesList.removeLast()
                            
                            realm?.add(recentSearch)
                        }
                    } else {
                        realm?.add(recentSearch)
                    }
                }
            } else {
                print("Search term already exists: \(searchTerm)")
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tap.cancelsTouchesInView = true
        tap.isEnabled = true
    }
    
    //--------------------------------------------------------------------------------------------------
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When there is no text, filteredData is the same as the original data
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        if searchText != ""{
            showTableView()
            // Could be search always the strings independently or could be to first search strings together and if nothing returns then search the terms separately but giving the user the option to do that

            if searchText.components(separatedBy: " ").count > 1 {
                let doubleString = searchText.components(separatedBy: " ")
				chartResults = tempChartHTML
				searchResults = tempHTML
				
                for i in 0...doubleString.count-1 {
                    // This statement is to prevent a 0 return from the "" generated when a space is introduced
                    if doubleString[i] != ""{
						chartResults = chartResults.filter { $0.lowercased().contains(doubleString[i].lowercased())}
						searchResults = searchResults.filter { $0.lowercased().contains(doubleString[i].lowercased())}
                    }
                }
                searchTerm = searchText
            } else {
				chartResults = tempChartHTML.filter { $0.lowercased().contains(searchText.lowercased())}
				searchResults = tempHTML.filter { $0.lowercased().contains(searchText.lowercased())}
                searchTerm = searchText
            }
			
			// To store the previous searchResults for when showAll results is active
			searchResultCache = searchResults
	// REMEMBER THIS
			let regexPattern = "Table \\w+ .+" // Best option at the moment
			let regex = try! NSRegularExpression(pattern: regexPattern)
//			
//			chartResults = searchResults.filter { result in
//				let range = NSRange(location: 0, length: result.utf16.count)
//				let matches = regex.firstMatch(in: result, options: [], range: range)
//				return matches != nil
//			}
			 print("####################################")
			 print(chartResults)
//			 print("####################################")
//			 print(searchResults)
			
			chapterResults = searchResults.filter { result in
				let range = NSRange(location: 0, length: result.utf16.count)
				let matches = regex.firstMatch(in: result, options: [], range: range)
				return matches == nil
			}
			
            isFiltering = true
        } else {
            isFiltering = false
            searchResults = [String]()
            showSuggestions()
        }
//        searchReturns.isHidden = false
        if searchResults.count == 0 || suggestionsView.isHidden == false {
            searchReturns.isHidden = true
        } else {
            searchReturns.text = String(searchResults.count) + " results in"
        }
        
        recentSearchesTableView.reloadData()
        tableView.reloadData()
    }
    
    //--------------------------------------------------------------------------------------------------
    // To adjust the recentSearchesTableView based on the content since auto resizing is not working as intended
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if recentSearchesList.count == 1 {
            recentSearchesTableView.frame.size.height = 36
        } else if recentSearchesList.count == 2 {
            recentSearchesTableView.frame.size.height = 72
        } else if recentSearchesList.count == 3 {
            recentSearchesTableView.frame.size.height = 108
        } else {
            recentSearchesTableView.frame.size.height = 0
        }
    }

    //--------------------------------------------------------------------------------------------------
    // To hide the keyboard when the user clicks search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }
    
    //--------------------------------------------------------------------------------------------------
    @objc func dismissKeyboard() {
        // To hide the keyboard when the user clicks search
        self.view.endEditing(true)
        tap.isEnabled = false
        Analytics.logEvent("search", parameters: [
            "query": (searchTerm ) as String,
        ])
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let webViewViewController = segue.destination as? WebViewViewController
        {
			if showCharts {
				webViewViewController.url = Bundle.main.url(forResource: Array(chapterIndex.chartCode.joined())[subArrayPointer], withExtension: "html")!
				webViewViewController.titlelabel = Array(chapterIndex.chartNested.joined())[subArrayPointer]
				webViewViewController.uniqueAddress = Array(chapterIndex.chartCode.joined())[subArrayPointer]
			} else {
				webViewViewController.url = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[subArrayPointer], withExtension: "html")!
				webViewViewController.titlelabel = Array(chapterIndex.chapterNested.joined())[subArrayPointer]
				webViewViewController.uniqueAddress = Array(chapterIndex.chapterCode.joined())[subArrayPointer]
			}
			
			webViewViewController.navTitle = navTitle
			webViewViewController.comingFromSearch = true
			webViewViewController.searchTerm = search.text != "" ? search.text : nil
			webViewViewController.hidesBottomBarWhenPushed = true
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
