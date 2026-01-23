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
    
	@IBOutlet weak var loader: UIActivityIndicatorView!
	@IBOutlet weak var loaderView: UIView!
	@IBOutlet weak var mainLoaderView: UIView!
	@IBOutlet var mainLoader: UIActivityIndicatorView!

    // Initialize Realm
    let realm = RealmHelper.sharedInstance.mainRealm()
    
    var tableViewCells: [Int : UITableViewCell] = [:]
    var subArrayPointer = 0
    var navTitle = "Placeholder SubChapter"
    var tempHTML = [String]()
	var tempChaptersHTML = [String]()
	var tempChartsHTML = [String]()
    let chapterIndex = ChapterIndex()

    var allSearchResults = [String]()
	var chapterResults = [String]()
	var chartResults = [String]()
	var allSearchResultsCache = [String]()
	var chaptersOnly = [[String]]()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Focus search bar when returning to this view
        if !isFiltering || searchTerm.isEmpty {
            search.becomeFirstResponder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        let navbarTitle = UILabel()
        navbarTitle.text = "Search"
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 2
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.7
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        navigationItem.backButtonDisplayMode = .minimal
        
        search.delegate = self

		guard let textField = search.value(forKey: "searchField") as? UITextField else { return }

			// Searchbar configuration
		textField.textColor = UIColor.searchBarText
		textField.attributedPlaceholder = NSAttributedString(
			string: "Enter Keywords to Search",
			attributes: [.foregroundColor: UIColor.searchBarText]
		)
		textField.layer.cornerRadius = 60
		textField.backgroundColor = UIColor.searchBar

		searchView.frame = CGRect(
			x: searchView.frame.origin.x,
			y: searchView.frame.origin.y,
			width: searchView.frame.width,
			height: search.frame.height + 10
		)

		textField.setSearchIcon(UIImage(named: "magnifyingGlass"), tintColor: UIColor.searchBarText)
		textField
			.setClearButton(UIImage(named: "icClear"), tintColor: UIColor.colorPrimary)

        navigationController?.navigationBar.setGradientBackground(to: self.navigationController!)
        navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        // Set Gradient to the width of the navigationBarda
		// searchView.setGradientBackground(size: CGRect(x: searchView.bounds.origin.x, y: searchView.bounds.origin.y, width: self.navigationController?.navigationBar.bounds.width ?? searchView.bounds.width, height: searchView.bounds.height))
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
		loaderView.isHidden = true
		mainLoaderView.isHidden = true

        // Keyboard dismissal recognizer
        tap.addTarget(self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
	func loadHTML() {
			// Load the htmls on the array - needs to be on viewDidLoad otherwise it duplicates the content
		let filename = "15_appendix_district_tb_coordinators_(by_district).html"
		let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let downloadedTbCoordinatorPath = documentsPath.appendingPathComponent(filename)

		do {
			var downloadedTbCoordinatorContent = try String(contentsOf: downloadedTbCoordinatorPath, encoding: .utf8)

//			print(downloadedTbCoordinatorContent)
			
			// Replace occurrences of the old path with the new file URL
			downloadedTbCoordinatorContent = downloadedTbCoordinatorContent.replacingOccurrences(
				of: "[\\s\n]+",
				with: " ",
				options: .regularExpression
			).trimmingCharacters(in: .whitespacesAndNewlines)

			downloadedTbCoordinatorContent = downloadedTbCoordinatorContent.replacingOccurrences(
				of: "<.*?>",
				with: "",
				options: .regularExpression,
				range: nil
			)

				// For Both Chapters and Charts Together
			for items in chapterIndex.chapterCode.joined() {
				let resourceName = items.components(separatedBy: ".")[0]

					// When the filename is  "15_appendix_district_tb_coordinators_(by_district)" add the download TB Coordinators content to be indexed
					// TODO: Needs thorough testing to properly check that all files text is being indexed
				if resourceName == "15_appendix_district_tb_coordinators_(by_district)" {
					tempHTML.append(downloadedTbCoordinatorContent)
					print(downloadedTbCoordinatorContent)
					continue
				}

				let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!

					// This converts a multiline string into a single file, the .whitespacesandnewlines doesn't work to do that job
				var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
				htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
				tempHTML.append(htmlString)
			}

				// For Charts
			for items in chapterIndex.chartCode.joined() {
				let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
					// This converts a multiline string into a single file, the .whitespacesandnewlines doesn't work to do that job
				var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
				htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
				tempChartsHTML.append(htmlString)
			}

				// For Chapters Only
				// To remove the tables from the chapterIndex.chapterCode array
				// Regex has been used to avoid creating another chapterOnly array inside the chapterIndex class
			let regexPattern = "^table_\\d+_.*"
			let figurePattern = "^fig1_factors_to_be_considered$"

			chaptersOnly = chapterIndex.chapterCode.filter { subarray in
				!subarray.contains { element in
					element.range(of: regexPattern, options: .regularExpression, range: nil, locale: nil) != nil ||
					element.range(of: figurePattern, options: .regularExpression, range: nil, locale: nil) != nil
				}
			}

			for items in chaptersOnly.joined() {
				let resourceName = items.components(separatedBy: ".")[0]

					// When the filename is  "15_appendix_district_tb_coordinators_(by_district)" add the download TB Coordinators content to be indexed
					// TODO: Needs thorough testing to properly check that all files text is being indexed
				if resourceName == "15_appendix_district_tb_coordinators_(by_district)" {
					tempChaptersHTML.append(downloadedTbCoordinatorContent)
					continue
				}

				let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
					// This converts a multiline string into a single file, the .whitespacesandnewlines doesn't work to do that job
				var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
				htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
				tempChaptersHTML.append(htmlString)
			}
		} catch {
			for items in chapterIndex.chapterCode.joined() {
				let resourceName = items.components(separatedBy: ".")[0]
				let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
				var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
				htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
				tempHTML.append(htmlString)
			}

			// For Charts
			for items in chapterIndex.chartCode.joined() {
				let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
				var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
				htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
				tempChartsHTML.append(htmlString)
			}

			// For Chapters Only
			// To remove the tables from the chapterIndex.chapterCode array
			// Regex has been used to avoid creating another chapterOnly array inside the chapterIndex class
			let regexPattern = "^table_\\d+_.*"
			let figurePattern = "^fig1_factors_to_be_considered$"

			chaptersOnly = chapterIndex.chapterCode.filter { subarray in
				!subarray.contains { element in
					element.range(of: regexPattern, options: .regularExpression, range: nil, locale: nil) != nil ||
					element.range(of: figurePattern, options: .regularExpression, range: nil, locale: nil) != nil
				}
			}
			for items in chaptersOnly.joined() {
				let resourceName = items.components(separatedBy: ".")[0]
				let path = Bundle.main.path(forResource: items.components(separatedBy: ".")[0], ofType: "html")!
				var htmlString = try! String(contentsOfFile: path).replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
				htmlString = htmlString.replacingOccurrences(of: "<.*?>", with: "", options: .regularExpression, range: nil)
				tempChaptersHTML.append(htmlString)
			}
		}
    }
    
    private func setupMainTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "SearchCell", bundle: nil), forCellReuseIdentifier: "searchCell")
		tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
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
	
	private func activeTabConfig(_ button: UIButton, isActive: Bool) {
		UIView.performWithoutAnimation {
			button.backgroundColor = isActive ? .colorPrimary : .colorBackgroundSecondary
			button.tintColor = isActive ? .colorWhite : .colorText
			button.setTitleColor(isActive ? .colorWhite : .colorText, for: .normal)
			button.isEnabled = true
			button.layoutIfNeeded()
		}
	}

	private func updateSearchResults(_ results: [String], description: String) {
		allSearchResults = results
		tableView.reloadData()
		searchReturns.text = results.count == 1 ?  "\(results.count) result in" :  "\(results.count) results in"
	}
	
	@objc private func showAllChapters() {
		showAll = true
		showChapters = false
		showCharts = false
        loaderConfig {
            self.updateSearchResults(self.allSearchResultsCache, description: "all chapters")
            self.configureTabs(activeButton: self.allChaptersChartsButton, inactiveButtons: [self.chaptersButton, self.chartsButton])
		}
	}
	
	@objc private func showChaptersOnly() {
		showAll = false
		showChapters = true
		showCharts = false
		loaderConfig {
            self.updateSearchResults(self.chapterResults, description: "chapters")
            self.configureTabs(activeButton: self.chaptersButton, inactiveButtons: [self.allChaptersChartsButton, self.chartsButton])
		}
	}
	
	@objc private func showChartsOnly() {
		showAll = false
		showChapters = false
		showCharts = true
		loaderConfig {
            self.updateSearchResults(self.chartResults, description: "charts")
            self.configureTabs(activeButton: self.chartsButton, inactiveButtons: [self.allChaptersChartsButton, self.chaptersButton])
		}
	}
	
	private func configureTabs(activeButton: UIButton, inactiveButtons: [UIButton]) {
		activeTabConfig(activeButton, isActive: true)
		inactiveButtons.forEach { activeTabConfig($0, isActive: false) }
	}
	
	func showSuggestions() {
		recentSearchesList = getRecentSearches()
		mainTableView.isHidden = true
		suggestionsView.isHidden = false
		searchReturns.isHidden = true
		searchReturns.text = "You may want to search for"
		
		recentSearchesView.isHidden = recentSearchesList.isEmpty
	}

    
    func getRecentSearchesObjects() -> [Search] {
        let recentSearches = realm!.objects(Search.self)
		return Array(recentSearches)
    }
    
    func getRecentSearches() -> [String] {
        let recentSearches = realm!.objects(Search.self)
		return Array(recentSearches.map { $0.recentSearch }).reversed()
    }
	
	func getFilteredSubChapterTableNames() -> [String] {
		let filteredSubChapterTableNames = chapterIndex.subChapterNames.filter { subChapter in
			let regex = try! NSRegularExpression(pattern: "^Table \\d+: \\s*|^Figure \\d+. \\s*", options: [])
			let range = NSRange(location: 0, length: subChapter.utf16.count)
			return regex.firstMatch(in: subChapter, options: [], range: range) != nil
		}
		
		return filteredSubChapterTableNames
	}
	
	
	// Loader Configurations
	func loaderConfig(completion: @escaping () -> Void) {
		setTimeout(delay: 0){
			self.loaderView.isHidden = false
			self.loader.startAnimating()
		}
		
		setTimeout(delay: 0.4) {
			self.loader.stopAnimating()
			self.mainTableView.isHidden = false
			self.loaderView.isHidden = true
			completion()
		}
	}

	func mainLoaderConfig(completion: @escaping () -> Void) {
		setTimeout(delay: 0){
			self.mainLoaderView.isHidden = false
			self.mainLoader.startAnimating()
		}

		setTimeout(delay: 0.4) {
			self.mainLoader.stopAnimating()
			self.mainTableView.isHidden = false
			self.mainLoaderView.isHidden = true
			completion()
		}
	}

	func setTimeout(delay: Double, closure: @escaping () -> Void) {
		DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
			closure()
		}
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
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recentSearchesList = getRecentSearches()
		
        if tableView == self.tableView {
            if isFiltering {
				return showCharts ? chartResults.count : allSearchResults.count
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
		let chartNames = getFilteredSubChapterTableNames()
        
        if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchCell
            cell.backgroundColor = UIColor.backgroundColor
            
			if isFiltering {
				if showCharts {
					let subchapterNameIndex = tempChartsHTML.firstIndex(of: chartResults[indexPath.row]) ?? 0
					
					// For Charts, Table Names should appear first
					cell.subchapterLabel.text = chartNames.indices.contains(subchapterNameIndex) ? chartNames[subchapterNameIndex] : nil
					// Use chartmapsubchapter for charts
					if chapterIndex.chartmapsubchapter.indices.contains(subchapterNameIndex) {
						cell.chapterLabel.text = chapterIndex.chartmapsubchapter[subchapterNameIndex]
					} else {
						cell.chapterLabel.text = ""
					}
					
					let text = chartResults[indexPath.row]
					let TSTrange = text.range(of: searchTerm, options: [.caseInsensitive])
					let startRange = text.index(TSTrange?.lowerBound ?? text.startIndex, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
					let endRange = text.index(TSTrange?.lowerBound ?? text.endIndex, offsetBy: 90, limitedBy: text.endIndex) ?? text.endIndex
					cell.contentLabel.text = "..." + String(text[startRange..<endRange]) + "..."

					if let chartName = cell.subchapterLabel.text,
                       chartName
                        .range(
                            of: #"^Table \d+:"#,
                            options: .regularExpression
                        ) != nil || chartName
                        .range(
                            of: #"^Figure 1."#,
                            options: .regularExpression
                        ) != nil {
						cell.chapterIcon.image = UIImage(named: "icChartGreen")
					} else {
						cell.chapterIcon.image = UIImage(named: "icChapterBlue")
					}
				} else if showChapters {
					// Safely resolve index into tempChaptersHTML, then map to names/labels only if within bounds
					guard indexPath.row < chapterResults.count else { return cell }
					guard let subchapterNameIndex = tempChaptersHTML.firstIndex(of: chapterResults[indexPath.row]) else {
						// If the filtered result cannot be mapped back, clear labels to avoid crash
						cell.subchapterLabel.text = ""
						cell.chapterLabel.text = ""
						cell.contentLabel.text = ""
						cell.chapterIcon.image = UIImage(named: "icChapterBlue")
						return cell
					}
					
					if chapterIndex.subChapterNames.indices.contains(subchapterNameIndex) {
						cell.subchapterLabel.text = chapterIndex.subChapterNames[subchapterNameIndex]
					} else {
						cell.subchapterLabel.text = ""
					}
					
					if chapterIndex.chaptermapsubchapter.indices.contains(subchapterNameIndex) {
						cell.chapterLabel.text = chapterIndex.chaptermapsubchapter[subchapterNameIndex]
					} else {
						cell.chapterLabel.text = ""
					}
					
					let text = chapterResults[indexPath.row]
					let TSTrange = text.range(of: searchTerm, options: [.caseInsensitive])
					let startRange = text.index(TSTrange?.lowerBound ?? text.startIndex, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
					let endRange = text.index(TSTrange?.lowerBound ?? text.endIndex, offsetBy: 90, limitedBy: text.endIndex) ?? text.endIndex
					cell.contentLabel.text = "..." + String(text[startRange..<endRange]) + "..."
					cell.chapterIcon.image = UIImage(named: "icChapterBlue")
				} else {
					let subchapterNameIndex = tempHTML.firstIndex(of: allSearchResults[indexPath.row]) ?? 0

					cell.subchapterLabel.text = chapterIndex.subChapterNames[subchapterNameIndex]
					if chapterIndex.chaptermapsubchapter.indices.contains(subchapterNameIndex) {
						cell.chapterLabel.text = chapterIndex.chaptermapsubchapter[subchapterNameIndex]
					} else {
						cell.chapterLabel.text = ""
					}
					
					let text = allSearchResults[indexPath.row]
					let TSTrange = text.range(of: searchTerm, options: [.caseInsensitive])
					let startRange = text.index(TSTrange?.lowerBound ?? text.startIndex, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
					let endRange = text.index(TSTrange?.lowerBound ?? text.endIndex, offsetBy: 90, limitedBy: text.endIndex) ?? text.endIndex
					cell.contentLabel.text = "..." + String(text[startRange..<endRange]) + "..."

						// Check if the chart name starts with "Table X:" where X is an integer
					if let chartName = cell.subchapterLabel.text,
						chartName.range(of: #"^Table \d+:"#, options: .regularExpression) != nil || chartName
                        .range(
                            of: #"^Figure 1."#,
                            options: .regularExpression
                        ) != nil {
						cell.chapterIcon.image = UIImage(named: "icChartGreen")
					} else {
							// Invalid format (does not start with "Table X:")
						cell.chapterIcon.image = UIImage(named: "icChapterBlue")
					}
				}

				let terms = [searchTerm as NSString]
				cell.contentLabel.attributedText = addBoldText(fullString: cell.contentLabel.text! as NSString, boldPartsOfString: terms)
				cell.contentLabel.isHidden = false

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
                    switch (showCharts, showChapters) {
                        case (true, _):
                            subArrayPointer = tempChartsHTML.firstIndex(of: chartResults[indexPath.row]) ?? 0
                        case (_, true):
                            // Safely derive pointer for chapters only
                            if indexPath.row < chapterResults.count,
                               let idx = tempChaptersHTML.firstIndex(of: chapterResults[indexPath.row]) {
                                subArrayPointer = idx
                            } else {
                                tableView.deselectRow(at: indexPath, animated: true)
                                return
                            }
                        default:
                            subArrayPointer = tempHTML.firstIndex(of: allSearchResults[indexPath.row]) ?? 0
                    }
                    
                } else {
                    subArrayPointer = indexPath.row
                }
                
                // FIX: Use charts mapping for charts
                if showCharts {
                    navTitle = chapterIndex.chartmapsubchapter.indices.contains(subArrayPointer) ? chapterIndex.chartmapsubchapter[subArrayPointer] : ""
                } else {
                    navTitle = chapterIndex.chaptermapsubchapter.indices.contains(subArrayPointer) ? chapterIndex.chaptermapsubchapter[subArrayPointer] : ""
                }
            
                addRecentSearch(searchTerm: searchTerm)

                // Analytics and tracking code
                Analytics.logEvent("search", parameters: [
                    "search": (searchTerm) as String,
                ])
                
                let safeIndex = min(subArrayPointer, max(0, chapterIndex.subChapterNames.count - 1))
                PendoManager.shared().track("search", properties: ["searchTerm": searchTerm, "selectedResult": chapterIndex.subChapterNames.indices.contains(safeIndex) ? chapterIndex.subChapterNames[safeIndex] : ""])
                
                performSegue(withIdentifier: "SegueToWebViewViewController", sender: nil)
            } else if tableView == self.searchSuggestionsTableView {
            search.text = suggestionsList[indexPath.row]
            searchTerm = suggestionsList[indexPath.row]
			
			mainLoaderConfig {
				self.addRecentSearch(searchTerm: self.searchTerm)
				self.searchBar(self.search, textDidChange: self.searchTerm)
			}
        } else {
            search.text = recentSearchesList[indexPath.row]
            searchTerm = recentSearchesList[indexPath.row]
			
			mainLoaderConfig {
				self.searchBar(self.search, textDidChange: self.searchTerm)
			}
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
        if !searchText.isEmpty {
            showTableView()

            // Normalize the query: lowercase and remove all whitespace
            let normalizedQuery = searchText.lowercased().replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)

            // Helper to normalize content strings the same way
            func normalized(_ s: String) -> String {
                return s.lowercased().replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
            }

            // Perform exact phrase contains matching on normalized strings
            allSearchResults = tempHTML.filter { normalized($0).contains(normalizedQuery) }
            chapterResults = tempChaptersHTML.filter { normalized($0).contains(normalizedQuery) }
            chartResults = tempChartsHTML.filter { normalized($0).contains(normalizedQuery) }

            searchTerm = searchText

            // Store for All tab cache
            allSearchResultsCache = allSearchResults
            isFiltering = true
        } else {
            isFiltering = false
            allSearchResults = [String]()
            showSuggestions()
        }
		
        if allSearchResults.count == 0 || suggestionsView.isHidden == false {
			searchReturns.text = "0 results in"
		} else {
			func resultText(for count: Int) -> String {
				return count == 1 ? "\(count) result in" : "\(count) results in"
			}
			
			if showCharts {
				searchReturns.text = resultText(for: chartResults.count)
			} else if showChapters {
				searchReturns.text = resultText(for: chapterResults.count)
			} else {
				searchReturns.text = resultText(for: allSearchResults.count)
			}

        }
        
        recentSearchesTableView.reloadData()
        tableView.reloadData()
    }
    
    //--------------------------------------------------------------------------------------------------
    // To adjust the recentSearchesTableView based on the content since auto resizing is not working as intended
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let itemHeight: CGFloat = 36
		let maxItems = 3
		let itemCount = min(recentSearchesList.count, maxItems)
		
		recentSearchesTableView.frame.size.height = itemHeight * CGFloat(itemCount)
	}


    //--------------------------------------------------------------------------------------------------
    // To hide the keyboard when the user clicks search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
		addRecentSearch(searchTerm: searchTerm)
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let webViewViewController = segue.destination as? WebViewViewController {
            let url: URL
            let titleLabel: String
            let uniqueAddress: String

            switch (showCharts, showChapters) {
                case (true, _):
                    let chartCodes = Array(chapterIndex.chartCode.joined())
                    let chartNested = Array(chapterIndex.chartNested.joined())
                    guard subArrayPointer < chartCodes.count,
                          subArrayPointer < chartNested.count,
                          subArrayPointer < chapterIndex.chartmapsubchapter.count else {
                        return
                    }
                    url = Bundle.main.url(forResource: chartCodes[subArrayPointer], withExtension: "html")!
                    titleLabel = chartNested[subArrayPointer]
                    uniqueAddress = chartCodes[subArrayPointer]

                case (_, true):
                    let chapterCodes = Array(chaptersOnly.joined())
                    let chapterNested = Array(chapterIndex.chapterNested.joined())
                    guard subArrayPointer < chapterCodes.count,
                          subArrayPointer < chapterNested.count else {
                        return
                    }
                    url = getFileURL(for: chapterCodes[subArrayPointer])
                    titleLabel = chapterNested[subArrayPointer]
                    uniqueAddress = chapterCodes[subArrayPointer]

                default:
                    let chapterCodes = Array(chapterIndex.chapterCode.joined())
                    let chapterNested = Array(chapterIndex.chapterNested.joined())
                    guard subArrayPointer < chapterCodes.count,
                          subArrayPointer < chapterNested.count else {
                        return
                    }
                    url = getFileURL(for: chapterCodes[subArrayPointer])
                    titleLabel = chapterNested[subArrayPointer]
                    uniqueAddress = chapterCodes[subArrayPointer]
            }

            webViewViewController.url = url
            webViewViewController.titlelabel = titleLabel
            webViewViewController.uniqueAddress = uniqueAddress

            webViewViewController.navTitle = titleLabel

            webViewViewController.comingFromSearch = true
            webViewViewController.searchTerm = search.text?.isEmpty == false ? search.text : nil
            webViewViewController.hidesBottomBarWhenPushed = true
        }
    }

    
    //--------------------------------------------------------------------------------------------------
    // Bolding function from online - https://exceptionshub.com/making-text-bold-using-attributed-string-in-swift.html
    func addBoldText(fullString: NSString, boldPartsOfString: Array<NSString>) -> NSAttributedString {
        let nonBoldFontAttribute: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        let boldString = NSMutableAttributedString(string: fullString as String, attributes: nonBoldFontAttribute)

        // Nothing to highlight
        guard let rawQuery = boldPartsOfString.first as String?, !rawQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return boldString
        }

        let text = fullString as String
        let lowerText = text.lowercased()
        let lowerQuery = rawQuery.lowercased()

        // Helper to apply attributes to a given NSRange if it's valid
        func applyHighlight(_ range: NSRange) {
            guard range.location != NSNotFound, NSMaxRange(range) <= boldString.length else { return }
            boldString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 12), range: range)
            boldString.addAttribute(.foregroundColor, value: UIColor.colorPrimary, range: range)
        }

        // 1) Prefer exact phrase matches (case-insensitive). Highlight all occurrences.
        var phraseRanges: [NSRange] = []
        if !lowerQuery.isEmpty {
            var searchRange = lowerText.startIndex..<lowerText.endIndex
            while let r = lowerText.range(of: lowerQuery, options: [.caseInsensitive], range: searchRange) {
                let nsRange = NSRange(r, in: lowerText)
                phraseRanges.append(nsRange)
                // advance
                searchRange = r.upperBound..<lowerText.endIndex
            }
        }

        if !phraseRanges.isEmpty {
            for r in phraseRanges { applyHighlight(r) }
            return boldString
        }

        // 2) If no phrase match, fall back to whole-word matches for each token.
        let tokens = lowerQuery
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty else { return boldString }

        // Build a regex that matches any token as a whole word: \b(token1|token2|...)\b
        // Escape special regex characters in tokens
        let escapedTokens = tokens.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = "\\b(" + escapedTokens.joined(separator: "|") + ")\\b"

        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: boldString.length))
            for match in matches {
                applyHighlight(match.range)
            }
        }

        return boldString
    }
}

