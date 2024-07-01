//
//  WebViewViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/27/21.
//

import UIKit
import WebKit
import RealmSwift
import FirebaseAnalytics
import FirebaseDynamicLinks

class WebViewViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, SaveFavoriteDelegate, SaveNoteDelegate, UITableViewDataSource, UITableViewDelegate, WKScriptMessageHandler {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var pseudoseparator: UIView!
    @IBOutlet weak var favoriteIcon: UIButton!
    
    @IBOutlet weak var searchTermView: UILabel!
    @IBOutlet weak var searchView: UIView!
    var identifier = ""
    var header = "Placeholder Content"
    var url: URL!
    var uniqueAddress: String!
    var titlelabel = "Placeholder Title"
    var datetemporary = "Updated"
    var navTitle = ""
    var comingFromSearch = false
    var searchTerm: String?
    var comingFromHyperLink = false
    var userSettings : UserSettings!
    var fontNumber = 100
    
    // Initialize the Realm database
    let realm = RealmHelper.sharedInstance.mainRealm()
//    let realm = try! Realm()
    var content : ContentPage!
    var note : Notes!
    var chapterIndex = ChapterIndex()
            
    var tableView: UITableView = ContentSizedTableView()
    var tableViewCells: [Int : UITableViewCell] = [:]
    var tableViewOriginalHeight = 0.0
    var tableFrame = CGRect()
    var tableButton = UIButton()
    var tableSeparator = UIView()
    var colorTags = [UIColor.black, UIColor.systemRed, UIColor.systemOrange, UIColor.systemYellow, UIColor.systemGreen, UIColor.systemTeal, UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple]
    
    var webView: WKWebView!
    var webViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
    
    var addNoteDialogView: SaveNote!
    var addFeedbackDialogView: FeedbackForm!
    
//    lazy var webView: WKWebView = {
//        let webConfiguration = WKWebViewConfiguration()
//        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
//        webView.uiDelegate = self
//        webView.navigationDelegate = self
//        webView.translatesAutoresizingMaskIntoConstraints = false
//        return webView
//    }()
    
    let bookmarkText = NSAttributedString(
        string: "Bookmark",
        attributes: [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 9.0)
        ]
    )
    
    let bookmarkedText = NSAttributedString(
        string: "Bookmarked",
        attributes: [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 9.0)
        ]
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let searchTerm = searchTerm, comingFromSearch, !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            searchView.isHidden = searchTerm.isEmpty
            searchTermView.text = searchTerm
        } else {
            searchView.isHidden = true
        }
   
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
        self.hidesBottomBarWhenPushed = true
                
        titleLabel.text = titlelabel
        dateLabel.text = "Updated \( chapterIndex.updateDate)"
        
        contentView.topAnchor.constraint(equalTo: pseudoseparator.bottomAnchor, constant: 5).isActive = true
        
//        setupUI()
        
//        // Realm
//        try! realm!.write
//        {
//            // Should only add a new entry if this entry is not already added there
//            if let currentContent = realm!.object(ofType:ContentPage.self, forPrimaryKey: uniqueAddress){
//                currentContent.lastOpened = Date()
//                currentContent.openedTimes += 1
//                // Assign the older entry to the current variable
//                content = currentContent
//            } else {
//                content = ContentPage()
//                content.name = titlelabel
//                content.url = uniqueAddress
//                content.chapterParent = navTitle
//                content.lastOpened = Date()
//                content.openedTimes += 1
//                // Add it to Realm
//                realm!.add(content)
//            }
//
//            // Save recently viewed chapters list
//            let lastAccessed = realm!.objects(ContentAccess.self)
//            // This determines the buffer that we are allowing
//            if lastAccessed.count > 7 {
//                realm!.delete(lastAccessed[0])
//            }
//
//            // Save history
//            if lastAccessed.filter("url == '\(content.url)'").count == 0 {
//                print("Thinks history is false")
//                let currentAccessedContent = ContentAccess()
//                currentAccessedContent.name = titlelabel
//                currentAccessedContent.url = uniqueAddress
//                currentAccessedContent.chapterParent = navTitle
//                currentAccessedContent.date = Date()
//                realm!.add(currentAccessedContent)
//
//                content.isHistory = true // This statement is useless unless I also change the variable when content is history gets refreshed
//            } else {
//                // Should move entry to the top of the history list...
//                let newAccessed = lastAccessed.filter("url == '\(content.url)'")
//                newAccessed[0].date = Date()
//            }
//        }
//
//        if content.favorite == true {
//            favoriteIcon.setImage(UIImage(systemName: "star.fill"), for: .normal)
//        }
        
        // Create WebView Content
        let config = WKWebViewConfiguration()
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        setupUI()
        
        // Log the page load
        Analytics.logEvent("page", parameters: [
            "page": (uniqueAddress ) as String,
        ])
        
        if let currentSettings = realm!.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings"){
            // Assign the older entry to the current variable
            userSettings = currentSettings
            fontNumber = userSettings.fontSize
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(fontSizeChanged(_:)), name: NSNotification.Name("FontSizeChanged"), object: nil)
        webView.load( URLRequest( url: url ))
    }
    
    @objc func fontSizeChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo, let newFontSize = userInfo["fontSize"] as? Int {
            fontNumber = newFontSize
            print("Changed the font size to \(fontNumber)")

            try? realm?.write {
                userSettings.fontSize = fontNumber
            }
            webView.reload()
        }
    }
        
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("FontSizeChanged"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if let currentContent = realm!.object(ofType:ContentPage.self, forPrimaryKey: uniqueAddress){
            RealmHelper.sharedInstance.update(currentContent, properties: [
                "lastOpened": Date(),
                "openedTimes": currentContent.openedTimes+1
            ]) { [weak self] updated in
                self!.content = currentContent
            }
            
        } else {
            content = ContentPage()
            content.name = titlelabel
            content.url = uniqueAddress
            content.chapterParent = navTitle
            content.lastOpened = Date()
            content.openedTimes += 1
            // Add it to Realm
//            try! realm.write
//                    {
//            realm.add(content)
//                    }
            RealmHelper.sharedInstance.save(content) { saved in
                //
            }
        }
        
        // Save recently viewed chapters list
        let lastAccessed  = realm!.objects(ContentAccess.self)
        // This determines the buffer that we are allowing
        if lastAccessed.count > 7 {
            RealmHelper.sharedInstance.delete(lastAccessed[0]) { deleted in
                //
            }
        }
        
        
        // Save history
        if lastAccessed.filter("url == '\(content.url)'").count == 0 {
            print("Thinks history is false")
            let currentAccessedContent = ContentAccess()
            currentAccessedContent.name = titlelabel
            currentAccessedContent.url = uniqueAddress
            currentAccessedContent.chapterParent = navTitle
            currentAccessedContent.date = Date()
            RealmHelper.sharedInstance.save(currentAccessedContent) { [weak self] saved in
                //
                RealmHelper.sharedInstance.update(self!.content, properties: [
                    "isHistory": true
                ]) { [weak self] updated in
                    //
                }
            }
            
//            content.isHistory = true // This statement is useless unless I also change the variable when content is history gets refreshed
        } else {
            // Should move entry to the top of the history list...
            let newAccessed = lastAccessed.filter("url == '\(content.url)'")
            RealmHelper.sharedInstance.update(newAccessed[0], properties: [
                "date": Date()
            ]) { [weak self] updated in
                //
            }
            
        }
        
        
        if content.favorite == true {
            favoriteIcon.setImage(UIImage(named: "icBookmarksFolderColored"), for: .normal)
            favoriteIcon.setAttributedTitle(bookmarkedText, for: .normal)
        }
        
        
       
        // Realm
//        try! realm!.write
//        {
//            // Should only add a new entry if this entry is not already added there
//            if let currentContent = RealmHelper.sharedInstance.mainRealm()!.object(ofType:ContentPage.self, forPrimaryKey: uniqueAddress){
//                currentContent.lastOpened = Date()
//                currentContent.openedTimes += 1
//                // Assign the older entry to the current variable
//                content = currentContent
//            } else {
//                content = ContentPage()
//                content.name = titlelabel
//                content.url = uniqueAddress
//                content.chapterParent = navTitle
//                content.lastOpened = Date()
//                content.openedTimes += 1
//                // Add it to Realm
//                realm!.add(content)
//            }
//
//            // Save recently viewed chapters list
//            let lastAccessed = realm!.objects(ContentAccess.self)
//            // This determines the buffer that we are allowing
//            if lastAccessed.count > 7 {
//                realm!.delete(lastAccessed[0])
//            }
//
//            // Save history
//            if lastAccessed.filter("url == '\(content.url)'").count == 0 {
//                print("Thinks history is false")
//                let currentAccessedContent = ContentAccess()
//                currentAccessedContent.name = titlelabel
//                currentAccessedContent.url = uniqueAddress
//                currentAccessedContent.chapterParent = navTitle
//                currentAccessedContent.date = Date()
//                realm!.add(currentAccessedContent)
//
//                content.isHistory = true // This statement is useless unless I also change the variable when content is history gets refreshed
//            } else {
//                // Should move entry to the top of the history list...
//                let newAccessed = lastAccessed.filter("url == '\(content.url)'")
//                newAccessed[0].date = Date()
//            }
//        }
//
//        if content.favorite == true {
//            favoriteIcon.setImage(UIImage(systemName: "star.fill"), for: .normal)
//        }
        
        // Load table if there are notes saved for this chapter
//        if content.notes.count > 0 {
//            loadTable()
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // This removes the favoriting if it gets deleted in the saved page
        if content.favorite == false {
            favoriteIcon.setImage(UIImage(named: "icBookmarksFolder"), for: .normal)
            favoriteIcon.setAttributedTitle(bookmarkText, for: .normal)
        }
        // Load table if there are notes saved for this chapter
        if content.notes.count > 0 {
            if tableView.superview == nil {
                loadTable()
            } else {
                tableView.reloadData()
            }
        } else {
            removeTable()
        }
        
        // Add observer to the WebView so that when the URL changes it triggers our detection function
        webView.addObserver(self, forKeyPath: "URL", options: [.new, .old], context: nil)
        // Only automate zoom feature for charts
//        if content.name.contains("Table"){
//            // Zoom to maximum capacity
//            webView.scrollView.setZoomScale(0.1, animated: true)
//            let rw = webView.scrollView.zoomScale
//            webView.scrollView.minimumZoomScale = rw
//            webView.scrollView.maximumZoomScale = rw
//            webView.scrollView.zoomScale = rw
//
//        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(false)
        
        // Navigate back to the previous screen so that when the viewcontroller comes back the screen is present
        webView.goBack()
    }
    
    //--------------------------------------------------------------------------------------------------
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let newValue = change?[.newKey] as? Int, let oldValue = change?[.oldKey] as? Int, newValue != oldValue {
            // Value Changed
            // .components(separatorBy: ".app/")
            print("new key is ",change?[.newKey] ?? "Couldn't print the new key")
        }else{
            //Value not Changed
            print("old key is ",change?[.oldKey] ?? "Couldn't print the old key")
        }

        // Find the actual string
        // When you click a link that becomes the new key
        // Even if the page doesn't change because you had it blocked, the new link becomes the old link, so I want to put a checker condition that only when both links come from within the app you should go through this function
        if let newValue = change?[.newKey], (newValue as AnyObject).debugDescription.hasPrefix("file:///"), let oldValue = change?[.oldKey], (oldValue as AnyObject).debugDescription.hasPrefix("file:///"){
            let newURL = change?[.newKey].debugDescription.components(separatedBy: "GA-TB-Reference-Guide.app/")[1] ?? "Couldn't print the new key"
            print("Loading within the app content", newURL)
            // Check if we are not going into a within page anchor link or we came from an anchor link and it's resetting the view regardless
            let oldURL = change?[.oldKey].debugDescription.components(separatedBy: "GA-TB-Reference-Guide.app/")[1] ?? "Couldn't print the old key"
            print(newURL)
            print(oldURL)
            if (!newURL.contains("#") /*&& !oldURL.contains("#")*/) || oldURL.hasPrefix("table_"){
                
                let urlsarray = Array(chapterIndex.chapterCode.joined()).firstIndex(of: newURL.components(separatedBy: ".")[0])
                
                // push view controller but animate modally
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "web") as! WebViewViewController

                let navigationController = self.navigationController
                
                // If there is an anchor present we want to take the user to that position on the file
                if newURL.contains("#"){
                    let anchor = "#"+newURL.components(separatedBy: "#")[1].replacingOccurrences(of: ")", with: "")
                    print("this is the anchor", anchor)
                    let baseURL = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0], withExtension: "html")!
                    vc.url = URL(string: anchor, relativeTo: baseURL)
                } else {
                    vc.url = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0], withExtension: "html")!
                }
                vc.titlelabel = Array(chapterIndex.chapterNested.joined())[urlsarray ?? 0]
                vc.navTitle = chapterIndex.chaptermapsubchapter[urlsarray ?? 0]
                vc.uniqueAddress = Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0]
                
                // Remove the observer for the previous screen so that it won't double fire when the URL changes again
                webView.removeObserver(self, forKeyPath: "URL")

                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            print("Loading outside of the app content")
            // newURL stays as the chapter because the webview stopsloading
            
            // This has been added to optionally cast to a URL in the event that the devices observer was obsolete from a previous load
            if let oldURL = change?[.oldKey] as? URL {
                
                //            let newURL = change?[.newKey] as! URL
                //            let oldURL = change?[.oldKey] as! URL
                comingFromHyperLink = true
                webView.stopLoading()
                
                let alertDelete = UIAlertController(title: "This link will open in your browser, do you want to continue?", message: "", preferredStyle: .alert)
                alertDelete.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    self.comingFromHyperLink = false
                    print("fires?",oldURL)
//                    print(newURL)
                    UIApplication.shared.open(oldURL, options: [:], completionHandler: nil)
                }))
                alertDelete.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    self.comingFromHyperLink = false
                }))
                self.present(alertDelete, animated: true, completion: nil)
                
                // Remove the observer for the previous screen so that it won't double fire when the URL changes again
                //            webView.removeObserver(self, forKeyPath: "URL")
                //            UIApplication.shared.open(newURL, options: Any, completionHandler: true)
                //            webView.goBack()
            }
        }
    }
    
    // This function is just preventing the within the app pages to move to the web links because there is no new page that we need to call the goBack() function from
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Comes to this function before knowing what the url is so it's always false")
//        if comingFromHyperLink == true {
//            decisionHandler(.cancel)
//            comingFromHyperLink = false
//        } else {
//            decisionHandler(.allow)
//        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        preferences.preferredContentMode = .mobile
        decisionHandler(.allow,preferences)
    }

    //--------------------------------------------------------------------------------------------------
    @IBAction func toggleFavorite(_ sender: UIButton){
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let sceneDelegate = windowScene.delegate as! SceneDelegate
        
        if let window = sceneDelegate.window
        {
            let saveFavoriteDialogView = SaveFavorite( frame: window.bounds, content: content, title: titlelabel, delegate: self )
            saveFavoriteDialogView.contentView.transform = CGAffineTransform( scaleX: 0, y: 0 )
            saveFavoriteDialogView.overlayView.alpha = 0
            window.addSubview( saveFavoriteDialogView )
            
            UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                saveFavoriteDialogView.overlayView.alpha = 0.5
                saveFavoriteDialogView.contentView.transform = CGAffineTransform( scaleX: 1.0, y: 1.0 )
            }, completion: { (value: Bool) in
            })
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    @IBAction func addNote(_ sender: UIButton){
        openNoteWindow(noteChosen: Notes())
    }
    
    //--------------------------------------------------------------------------------------------------
    @IBAction func backToHomepage(_ sender: UIButton){
        navigationController?.popToRootViewController(animated: true)
    }
    
    //--------------------------------------------------------------------------------------------------
    @IBAction func shareContent(_ sender: UIButton){
        // Add activity indicator if using short link
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "apphatcherygatbreferenceguide.page.link"
        components.path = "/share"
        
        let chapterIDQueryItem = URLQueryItem(name: "chapterId", value: uniqueAddress)
        let isChartQueryItem = URLQueryItem(name: "androidIsPage", value: uniqueAddress.contains("table") ? "0" : "1")
        components.queryItems = [chapterIDQueryItem,isChartQueryItem]
        
        guard let linkParameter = components.url else { return }
        print("I am sharing \(linkParameter.absoluteString)")
        
        // Dynamic Link
        guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: "https://apphatcherygatbreferenceguide.page.link") else {
            print("Couldn't create Dynamic Link Component")
            return
        }
        
        if let myBundleID = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleID)
        }
        shareLink.iOSParameters?.appStoreID = "1583294462"
        shareLink.androidParameters = DynamicLinkAndroidParameters(packageName: "com.apphatchery.tb.guide")
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = navTitle
        shareLink.socialMetaTagParameters?.descriptionText = titleLabel.text
        // Grab this from github
//        shareLink.socialMetaTagParameters?.imageURL = URL.init(string: "https://github.com/AppHatchery/GA-TB-Reference-Guide-Web/blob/main/pages/figure1.png")
        
        guard let longURL = shareLink.url else { return }
        print("The long dynamic link is \(longURL.absoluteString)")
//        shareChapter(url: longURL)
        
        // Sets a drawback because it's slow, so we might make it long and that's it
        shareLink.shorten { [weak self] url, warnings, error in
            if let error = error {
                print("Got an error shortening the dynamic link \(error)")
                // If for any reason the link shortening doesn't work, then send the long link URL
                self?.shareChapter(url: longURL)
                return
            }

            if let warnings = warnings {
                for warning in warnings {
                    print("FDL Warning: \(warning)")
                }
            }

            guard let url = url else { return }
            print("I have a short URL \(url.absoluteString)")
            self?.shareChapter(url: url)
        }
    }
    
    func shareChapter(url: URL){
        // This is text to accompany the
//        let promoText = "Check out this subchapter of the TB Reference Guide "
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    //--------------------------------------------------------------------------------------------------
    @IBAction func fontSettings(_ sender: UIButton) {
        let popUpOverlay = FontSettingsView()
        popUpOverlay.displayPopUp(sender:self)
    }
    
    @IBAction func closeSearchBar(_ sender: UIButton) {
        searchView.isHidden = true
        removeHighlights()
    }
    
    func highlightSearch(term: String)  {
        
        var terms = term.split(separator: " ").map({String($0)})
        if !terms.contains(term) {terms.append(term)}
        
        if let path = Bundle.main.url(forResource: "WebView", withExtension: "js") {
            do{
                let data:Data = try Data(contentsOf: path)
                let jsCode:String = String(decoding: data, as: UTF8.self)
                
                
                //print( jsCode)
                
                //inject the search code
                webView.evaluateJavaScript(jsCode, completionHandler: nil)
                
                //search function
                for (i, t) in terms.enumerated() {
                    let searchString = "WKWebView_HighlightAllOccurencesOfString('\(t)', \(i == 0))"
                    //perform search
                    webView.evaluateJavaScript(searchString, completionHandler: nil)
                }
                
            } catch {
                print("could not load javascript:\(error)")

            }
        
            
        }
    }
    
    func removeHighlights() {
        
        if let path = Bundle.main.url(forResource: "WebView", withExtension: "js") {
            do{
                let data:Data = try Data(contentsOf: path)
                let jsCode:String = String(decoding: data, as: UTF8.self)
                webView.evaluateJavaScript(jsCode, completionHandler: nil)
                webView.evaluateJavaScript("WKWebView_RemoveAllHighlights()", completionHandler: nil)
            } catch {
                print("could not load javascript:\(error)")

            }
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let urlHeader = webView.url?.absoluteString, urlHeader.hasPrefix("file:///"){
            
            let path = Bundle.main.path(forResource: "uikit", ofType: "css")!
            // This converts a multiline string into a single file, the .whitespacesandnewlines doesn't work to do that job
            let cssString = try! String(contentsOfFile: path).replacingOccurrences(of: "\n", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
            
            let path2 = Bundle.main.path(forResource: "style", ofType: "css")!
            let cssString2 = try! String(contentsOfFile: path2).replacingOccurrences(of: "\n", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            // Could potentially replace this with just the link to the file rather than having to convert it to string, save some computational power
            let jsString2 = "var style2 = document.createElement('style'); style2.innerHTML = '\(cssString2)'; document.head.appendChild(style2);"
            
//            webView.evaluateJavaScript(jsString, completionHandler: nil)
            let js3 = "var script2 = document.createElement('script'); script2.src = 'uikit-icons.js'; document.body.appendChild(script2);"
            webView.evaluateJavaScript(jsString2, completionHandler: nil)
            webView.evaluateJavaScript(js3, completionHandler: nil)
            let textSize = fontNumber >= 75 ? fontNumber : 100
            let javascript = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(textSize)%'"
            webView.evaluateJavaScript(javascript) { (response, error) in
                print()
            }
            if let searchTerm = searchTerm {
                highlightSearch(term: searchTerm)
            }
            
            
            
        } else {
            print("outside the app, don't apply styling")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
    
    //--------------------------------------------------------------------------------------------------
    func loadTable() {
        if tableView.superview == nil {
            print("making a new tbale")
            tableView = ContentSizedTableView(frame: CGRect( x: 20, y: pseudoseparator.frame.origin.y+10, width: view.frame.width-20, height: 65 ))
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UINib(nibName: "ChapterNoteTableViewCell", bundle: nil), forCellReuseIdentifier: "chapterNote")
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = UITableView.automaticDimension
            tableView.separatorStyle = .none
            tableView.backgroundColor = UIColor.backgroundColor

    //        tableView.isScrollEnabled = false
            // the frame trully is not the entire contentsize because you need to scroll down for the table to register the entire size of the content
            tableFrame = tableView.frame
            
            separatorHeightConstraint.isActive = false
//            separator.removeConstraint(separatorHeightConstraint)

            view.addSubview(tableView)
            
            // Constraint the tableview to fit between the webview and the separators
            tableView.leftAnchor.constraint( equalTo: view.leftAnchor, constant: 20 ).isActive = true
            tableView.rightAnchor.constraint( equalTo: view.rightAnchor ).isActive = true
            tableView.topAnchor.constraint(equalTo: pseudoseparator.topAnchor,constant: 0.5).isActive = true
            
            tableViewOriginalHeight = Double(tableView.frame.height)
            
            UIView.animate(withDuration: 0.25, delay: 0.01, options: .curveLinear, animations: {
                self.contentView.topAnchor.constraint(equalTo: self.tableView.bottomAnchor).isActive = true
                self.view.layoutIfNeeded()
            }, completion: { finished in
            })
//            contentView.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
            
            tableSeparator = UIView(frame: CGRect(x: 20, y: 15, width: view.frame.width - 40, height: 0.5))
            tableSeparator.backgroundColor = UIColor.lightGray
            contentView.addSubview(tableSeparator)
            
            tableButton = UIButton(frame: CGRect(x: tableSeparator.frame.width/2 - 5, y: tableSeparator.frame.origin.y-15.25, width: 30, height: 30))
            tableButton.layer.cornerRadius = 15
            tableButton.setBackgroundImage(UIImage(named: "downArrow"), for: .normal)
            tableButton.isUserInteractionEnabled = true
            tableButton.dropShadow()
            
            tableButton.addTarget(self, action: #selector(expandNotes), for: .touchUpInside)
            tableButton.isHidden = true
            contentView.addSubview(tableButton)
            // Update constraint of webview top to make space for the incoming button
            webViewTopConstraint.constant = 30
            if content.notes.count > 1 {
                tableButton.isHidden = false
                tableSeparator.isHidden = false
            }
        }
    }
    
    @objc func expandNotes(_ sender: UIButton, expand: Bool){
        // Would be nice to make it as big as the amount of rows, rather than a fixed height governed by the view
        if sender.backgroundImage(for: .normal) == UIImage(named: "downArrow") {
            tableFrame.size.height = tableView.contentSize.height
            sender.setBackgroundImage(UIImage(named: "upArrow"), for: .normal)
        } else {
            tableFrame.size.height = 65
            sender.setBackgroundImage(UIImage(named: "downArrow"), for: .normal)
        }
        // Condition for only expanding table
        if expand == true {
            tableFrame.size.height = tableView.contentSize.height+65
            sender.setBackgroundImage(UIImage(named: "upArrow"), for: .normal)
        }
        
        print(tableView.contentSize.height)
        if content.notes.count > 1 {
            tableButton.isHidden = false
            tableSeparator.isHidden = false
        }
        UIView.animate(withDuration: 0.25, delay: 0.01, options: .curveLinear, animations: {
            self.tableView.frame = self.tableFrame
          self.view.layoutIfNeeded()
        }, completion: { finished in
            print("table changed height",self.tableView.frame.height)
            print("size of contentFrame",self.tableView.contentSize)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ( content.notes.count > 1){
            print("content is more than 1")
            tableButton.isHidden = false
            tableSeparator.isHidden = false
        }
        return content.notes.count
    }
    
    private func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.estimatedRowHeight //UITableView.automaticDimension
    }
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "chapterNote", for: indexPath) as! ChapterNoteTableViewCell
        cell.backgroundColor = UIColor.backgroundColor
        cell.header.text = "Note - Last Edited \(content.notes[content.notes.count-1-indexPath.row].lastEdited )"
        cell.content.text = content.notes[content.notes.count-1-indexPath.row].content
        cell.colorTag.backgroundColor = colorTags[content.notes[content.notes.count-1-indexPath.row].colorTag]
        tableViewCells[content.notes.count-1-indexPath.row] = cell
        // remove the grey background selector for cells after selected a note
        cell.selectionStyle = .none
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print(cell.frame.size.height)
        tableFrame.size.height += cell.frame.size.height
//        self.tableViewHeight += cell.frame.size.height
//        tableViewBillsHeight.constant = self.tableViewHeight
    }
    
    // Missing the Edit note function which can come here
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let pickedNote   = realm!.object(ofType: Notes.self, forPrimaryKey: content.notes[content.notes.count-1-indexPath.row].id){
            
            openNoteWindow(noteChosen: pickedNote)
        }
    }
    // Need to populate with content of note coming from the cell selection itself
    // Potentially will need to attach an observer on that edit button that triggers the view as well
    
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete
         {
            if let contentDatabase   = realm!.object(ofType: Notes.self, forPrimaryKey: content.notes[content.notes.count-1-indexPath.row].id){
                RealmHelper.sharedInstance.delete(contentDatabase) { deleted in
                    //
                }
            }
            
//            try! realm!.write
//            {
//                if let contentDatabase = realm!.object(ofType: Notes.self, forPrimaryKey: content.notes[content.notes.count-1-indexPath.row].id){
//                    realm!.delete(contentDatabase)
//                }
//            }
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            expandNotes(tableButton,expand: true)
            if content.notes.count == 0 {
                removeTable()
           }
         }
    }
    
    //--------------------------------------------------------------------------------------------------
    func setupUI() {
//        self.view.backgroundColor = .white
        contentView.addSubview(webView)
        
        webViewTopConstraint = webView.topAnchor
            .constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            webViewTopConstraint,
            webView.leftAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            webView.bottomAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            webView.rightAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -5)
        ])
    }
    
    //--------------------------------------------------------------------------------------------------
    func didSaveName( _ name: String)
    {
        let bookmarkedText = NSAttributedString(
            string: "Bookmarked",
            attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 9.0)
            ]
        )
        
        // let realm = try! Realm()
        
        RealmHelper.sharedInstance.update(content, properties: [
            "favoriteName": name,
            "favorite": true
        ]) { [weak self] updated in
            //
            self?.favoriteIcon.setImage(UIImage(named: "icBookmarksFolderColored"), for: .normal)
            self?.favoriteIcon.setAttributedTitle(bookmarkedText, for: .normal)
        }
            
//        try! realm.write
//        {
//            content.favoriteName = name
//            content.favorite = true
//            favoriteIcon.setImage(UIImage(systemName: "star.fill"), for: .normal)
//        }
        
        Analytics.logEvent("bookmark", parameters: [
            "bookmark": (uniqueAddress ) as String,
        ])
    }
    
    //--------------------------------------------------------------------------------------------------
    func didRemoveFavorite( )
    {
        let bookmarkText = NSAttributedString(
            string: "Bookmark",
            attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 9.0)
            ]
        )
        
        // let realm = try! Realm() Realm()
        
        RealmHelper.sharedInstance.update(content, properties: [
            "favoriteName": "",
            "favorite": false
        ]) { [weak self] updated in
            //
            self?.favoriteIcon.setImage(UIImage(named: "icBookmarksFolder"), for: .normal)
            self?.favoriteIcon.setAttributedTitle(bookmarkText, for: .normal)
        }
        
//        try!  realm!.write
//        {
//            content.favoriteName = ""
//            content.favorite = false
//            favoriteIcon.setImage(UIImage(systemName: "star"), for: .normal)
//        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func didSaveNote(_ note: Notes )
    {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-YYYY"
        // let realm = try! Realm()
        
        if !note.savedToRealm {
            RealmHelper.sharedInstance.update(note, properties: [
                "subChapterURL": uniqueAddress!,
                "savedToRealm": true,
                "lastEdited": formatter.string(from: Date()),
                "subChapterName": titlelabel
            ]) { updated in
                //
                RealmHelper.sharedInstance.appendNote(self.content, property: self.content.notes, itemToAppend: self.note) { appended in
                        //
                    print("appended the note properly?")
                }
            }
        } else {
            RealmHelper.sharedInstance.update(note, properties: [
                "lastEdited": formatter.string(from: Date()),
                "subChapterName": titlelabel
            ]) { updated in
                //
            }
        }

//        content.notes.append(note)
        expandNotes(self.tableButton,expand: true)
        
        
//        try! realm!.write
//        {
//            note.lastEdited = formatter.string(from: Date())
//            note.subChapterName = titlelabel
//
//            if !note.savedToRealm
//            {
//                note.subChapterURL = uniqueAddress
//                note.savedToRealm = true
//                // Add new entry to Realm
//                realm!.add(note)
//                // Save to the chapter
//                content.notes.append(note)
//                expandNotes(tableButton,expand: true)
//            }
//            // Add the content changes necessary to the tableview or refresh it if necessary, though I could maybe do this in another view and just throw it on top of this one, much like the protocols in HomeTown
//
//        }
        if content.notes.count == 1  {
            loadTable()
            tableView.reloadData()
        } else {
            tableView.reloadData()
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func didDeleteNote(_ note: Notes )
    {
//        // let realm = try! Realm() Realm()
        RealmHelper.sharedInstance.delete(note) { deleted in
            //
        }
        
//        try!  realm!.write
//        {
//            realm!.delete(note)
//        }
        if content.notes.count > 0 {
            tableView.reloadData()
            expandNotes(tableButton,expand: true)
        } else {
            removeTable()
        }
    }
    
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let searchViewController = segue.destination as? SearchViewController
        {
            searchViewController.size = CGRect.init(x: 0, y: 0, width: view.frame.width, height: 60)
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func removeTable()
    {
        UIView.animate(withDuration: 0.3, delay: 0.01, options: .curveLinear, animations: {
            self.tableView.frame.size.height = 0
            self.separatorHeightConstraint = self.pseudoseparator.heightAnchor.constraint(equalToConstant: 0.5)
            self.separatorHeightConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { finished in
            self.tableView.removeFromSuperview()
            self.tableButton.removeFromSuperview()
            self.tableSeparator.removeFromSuperview()
            self.webViewTopConstraint.constant = 0.5
        })
    }
    
    func openNoteWindow(noteChosen: Notes)
    {
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let sceneDelegate = windowScene.delegate as! SceneDelegate
        
        if let window = sceneDelegate.window
        {
            // Need to feed in here the note that you tap on, otherwise feed in a totally new note
            // Look at the sender, either the UIButton or the UITableViewCell
            addNoteDialogView = SaveNote( frame: window.bounds, content: content, oldNote: noteChosen, delegate: self )
            if noteChosen != Notes() {
                note = noteChosen
            }
            addNoteDialogView.contentView.transform = CGAffineTransform( scaleX: 0, y: 0 )
            addNoteDialogView.overlayView.alpha = 0
                        
            window.addSubview( addNoteDialogView )
            
            UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                self.addNoteDialogView.overlayView.alpha = 0.5
                self.addNoteDialogView.contentView.transform = CGAffineTransform( scaleX: 1.0, y: 1.0 )
            }, completion: { (value: Bool) in
                // Load the correct button sizes and shapes
                for button in self.addNoteDialogView.colors {
                    button.layer.cornerRadius = button.frame.width/2
                }

                self.addNoteDialogView.highlightedColor = UIView(frame: self.addNoteDialogView.colors[0].bounds)
                self.addNoteDialogView.highlightedColor.frame.origin.x -= 3
                self.addNoteDialogView.highlightedColor.frame.origin.y -= 3
                self.addNoteDialogView.highlightedColor.frame.size.width += 6
                self.addNoteDialogView.highlightedColor.frame.size.height += 6

                self.addNoteDialogView.highlightedColor.layer.cornerRadius = self.addNoteDialogView.highlightedColor.frame.width/2
            
                self.addNoteDialogView.highlightedColor.backgroundColor = UIColor.clear
                self.addNoteDialogView.highlightedColor.layer.borderWidth = 1.5
                self.addNoteDialogView.highlightedColor.layer.borderColor = UIColor.systemBlue.cgColor
                self.addNoteDialogView.highlightedColor.layer.cornerRadius = self.addNoteDialogView.highlightedColor.frame.width/2
                // Defaulting to black color selected
                self.addNoteDialogView.colors[self.note.colorTag].addSubview(self.addNoteDialogView.highlightedColor)
            })
            
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
            customView.backgroundColor = UIColor( red: 0xd5/255.0, green: 0xd8/255.0, blue: 0xdc/255.0, alpha: 1)

            let doneButton = UIButton( frame: CGRect( x: view.frame.width - 70 - 10, y: 0, width: 70, height: 44 ))
            doneButton.setTitle( "Dismiss", for: .normal )
            doneButton.setTitleColor( UIColor.systemBlue, for: .normal)
            doneButton.addTarget( self, action: #selector( self.dismissKeyboard), for: .touchUpInside )
            customView.addSubview( doneButton )
            addNoteDialogView.noteField.inputAccessoryView = customView
        }
    }
    
    func openFeedbackWindow(parent: String, title: String)
    {
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let sceneDelegate = windowScene.delegate as! SceneDelegate
        
        if let window = sceneDelegate.window
        {
            // Need to feed in here the note that you tap on, otherwise feed-in a totally new note
            // Look at the sender, either the UIButton or the UITableViewCell
            addFeedbackDialogView = FeedbackForm( frame: window.bounds, parent: parent, title: title )
            
            addFeedbackDialogView.contentView.transform = CGAffineTransform( scaleX: 0, y: 0 )
            addFeedbackDialogView.overlayView.alpha = 0
                        
            window.addSubview( addFeedbackDialogView )
            
            UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                self.addFeedbackDialogView.overlayView.alpha = 0.5
                self.addFeedbackDialogView.contentView.transform = CGAffineTransform( scaleX: 1.0, y: 1.0 )
            }, completion: { (value: Bool) in
                // Load the correct button sizes and shapes
            })
        }
    }
    
    
    
    //--------------------------------------------------------------------------------------------------
    @objc func dismissKeyboard() {
        // To hide the keyboard when the user clicks search
        self.addNoteDialogView.endEditing(true)
    }
}
