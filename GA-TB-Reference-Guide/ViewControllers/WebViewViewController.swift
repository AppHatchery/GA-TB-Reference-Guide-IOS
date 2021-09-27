//
//  WebViewViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/27/21.
//

import UIKit
import WebKit
import RealmSwift

class WebViewViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, SaveFavoriteDelegate, SaveNoteDelegate, UITableViewDataSource, UITableViewDelegate, WKScriptMessageHandler {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var favoriteIcon: UIButton!
    
    var identifier = ""
    var header = "Placeholder Content"
    var url: URL!
    var uniqueAddress: String!
    var titlelabel = "Placeholder Title"
    var navTitle = ""
    var comingFromSearch = false
    var comingFromHyperLink = false
    
    // Initialize the Realm database
    let realm = try! Realm()
    var content : ContentPage!
    var note : Notes!
    var chapterIndex = ChapterIndex()
        
    var tableView: UITableView = ContentSizedTableView()
    var tableViewCells: [Int : UITableViewCell] = [:]
    var colorTags = [UIColor.black, UIColor.systemRed, UIColor.systemOrange, UIColor.systemYellow, UIColor.systemGreen, UIColor.systemTeal, UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple]
    
    var webView: WKWebView!
    
//    lazy var webView: WKWebView = {
//        let webConfiguration = WKWebViewConfiguration()
//        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
//        webView.uiDelegate = self
//        webView.navigationDelegate = self
//        webView.translatesAutoresizingMaskIntoConstraints = false
//        return webView
//    }()
    
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(tapGlobalSearch))
        
        titleLabel.text = titlelabel
        
//        loadTable()

        contentView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 5).isActive = true
//        setupUI()
        
        // Realm
        try! realm.write
        {
            // Should only add a new entry if this entry is not already added there
            if let currentContent = realm.object(ofType:ContentPage.self, forPrimaryKey: uniqueAddress){
                currentContent.lastOpened = Date()
                currentContent.openedTimes += 1
                // Assign the older entry to the current variable
                content = currentContent
            } else {
                content = ContentPage()
                content.name = titlelabel
                content.url = uniqueAddress
                content.chapterParent = navTitle
                content.lastOpened = Date()
                content.openedTimes += 1
                // Add it to Realm
                realm.add(content)
            }
            
            // Save recently viewed chapters list
            let lastAccessed = realm.objects(ContentAccess.self)
            // This determines the buffer that we are allowing
            if lastAccessed.count > 7 {
                realm.delete(lastAccessed[0])
            }
            
            // Save history
            if content.isHistory == false {
                print("Thinks history is false")
                let currentAccessedContent = ContentAccess()
                currentAccessedContent.name = titlelabel
                currentAccessedContent.url = uniqueAddress
                currentAccessedContent.chapterParent = navTitle
                realm.add(currentAccessedContent)
                
                content.isHistory = true
            } else {
                // Should move this to the top of the list...
                
            }
        }
        
        if content.favorite == true {
            favoriteIcon.setBackgroundImage(UIImage(systemName: "star.fill"), for: .normal)
        }
        
        // Create WebView Content
        let config = WKWebViewConfiguration()
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        setupUI()
        
        webView.load( URLRequest( url: url ))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // Load table if there are notes saved for this chapter
        if content.notes.count > 0 {
            loadTable()
        }
        
        // Add observer to the WebView so that when the URL changes it triggers our detection function
        webView.addObserver(self, forKeyPath: "URL", options: [.new, .old], context: nil)
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
            if (!newURL.contains("#") && !oldURL.contains("#")) || oldURL.hasPrefix("table_"){
                let urlsarray = Array(chapterIndex.chapterCode.joined()).firstIndex(of: newURL.components(separatedBy: ".")[0])
                
                // push view controller but animate modally
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "web") as! WebViewViewController

                let navigationController = self.navigationController
                
                vc.url = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0], withExtension: "html")!
                vc.titlelabel = Array(chapterIndex.chapterNested.joined())[urlsarray ?? 0]
                vc.navTitle = chapterIndex.chaptermapsubchapter[urlsarray ?? 0]
                vc.uniqueAddress = Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0]
                
                // Remove the observer for the previous screen so that it won't double fire when the URL changes again
                webView.removeObserver(self, forKeyPath: "URL")

                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            print("Loading outside of the app content")
            let newURL = change?[.newKey] as! URL
            comingFromHyperLink = true
            
            let alertDelete = UIAlertController(title: "This link will open in your browser, do you want to continue?", message: "", preferredStyle: .alert)
            alertDelete.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                self.comingFromHyperLink = false
                UIApplication.shared.open(newURL, options: [:], completionHandler: nil)
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
    
    // This function is just preventing the within the app pages to move to the web links because there is no new page that we need to call the goBack() function from
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if comingFromHyperLink == true {
            decisionHandler(.cancel)
            comingFromHyperLink = false
        } else {
            decisionHandler(.allow)
        }
    }
//
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        if let url = navigationAction.request.url, ...handle in Safari … {
//            decisionHandler(.cancel)
//            UIApplication.shared.openURL(url)
//        } else {
//            decisionHandler(.allow)
//        }
//    }

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
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let sceneDelegate = windowScene.delegate as! SceneDelegate
        
        if let window = sceneDelegate.window
        {
            // Need to feed in here the note that you tap on, otherwise feed in a totally new note
            // Look at the sender, either the UIButton or the UITableViewCell
            let addNoteDialogView = SaveNote( frame: window.bounds, content: content, oldNote: Notes(), delegate: self )
            addNoteDialogView.contentView.transform = CGAffineTransform( scaleX: 0, y: 0 )
            addNoteDialogView.overlayView.alpha = 0
            window.addSubview( addNoteDialogView )
            
            UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                addNoteDialogView.overlayView.alpha = 0.5
                addNoteDialogView.contentView.transform = CGAffineTransform( scaleX: 1.0, y: 1.0 )
            }, completion: { (value: Bool) in
            })
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
            
    //        let jsString2 = "var style2 = document.createElement('style'); style2.rel='stylesheet'; style2.href = 'style.css'; document.head.appendChild(style2);"
            
            webView.evaluateJavaScript(jsString, completionHandler: nil)
            webView.evaluateJavaScript(jsString2, completionHandler: nil)
            
    //        let js = getMyJavaScript()
//            let path3 = Bundle.main.path(forResource: "uikit", ofType: "js")!
//            let js = try! String(contentsOfFile: path3)
                //.replacingOccurrences(of: "\n", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    //        let js = "var script = document.createElement('script'); script.src = 'uikit-copy.js'; document.body.appendChild(script);"

//            webView.evaluateJavaScript(js, completionHandler: nil)
            
            let js3 = "var script2 = document.createElement('script'); script2.src = 'uikit-icons.js'; document.body.appendChild(script2);"
            webView.evaluateJavaScript(js3, completionHandler: nil)
        } else {
            print("outside the app, don't apply styling")
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
    }
    
    //--------------------------------------------------------------------------------------------------
    func loadTable() {
        tableView = ContentSizedTableView(frame: CGRect( x: 20, y: separator.frame.origin.y+10, width: view.frame.width-20, height: 120 ))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ChapterNoteTableViewCell", bundle: nil), forCellReuseIdentifier: "chapterNote")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
//        tableView.isScrollEnabled = false
                
        view.addSubview(tableView)
        
        // Constraint the tableview to fit between the webview and the separators
        tableView.leftAnchor.constraint( equalTo: view.leftAnchor, constant: 20 ).isActive = true
        tableView.rightAnchor.constraint( equalTo: view.rightAnchor ).isActive = true
        tableView.topAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: tableView.topAnchor,constant: 120).isActive = true
        
        contentView.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.notes.count
    }
    
    private func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "chapterNote", for: indexPath) as! ChapterNoteTableViewCell
        cell.header.text = "Note - Last Edited \(content.notes[indexPath.row].lastEdited )"
        cell.content.text = content.notes[indexPath.row].content
        cell.colorTag.backgroundColor = colorTags[content.notes[indexPath.row].colorTag]
        tableViewCells[indexPath.row] = cell
                
        return cell
    }
    
    //--------------------------------------------------------------------------------------------------
    @objc func tapGlobalSearch(){
        // If you came from the search controller then pop back the view controller, otherwise navigate there
        webView.removeObserver(self, forKeyPath: "URL")
        if comingFromSearch == true {
            self.navigationController?.popViewController(animated: true)
        } else {
            performSegue(withIdentifier: "SegueToSearchViewController", sender: nil)
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func setupUI() {
        self.view.backgroundColor = .white
        contentView.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor
                .constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor),
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
        let realm = try! Realm()
        
        try! realm.write
        {
            content.favoriteName = name
            content.favorite = true
            favoriteIcon.setBackgroundImage(UIImage(systemName: "star.fill"), for: .normal)
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func didRemoveFavorite( )
    {
        let realm = try! Realm()
        
        try! realm.write
        {
            content.favoriteName = ""
            content.favorite = false
            favoriteIcon.setBackgroundImage(UIImage(systemName: "star"), for: .normal)
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func didSaveNote(_ note: Notes )
    {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-YYYY"
        let realm = try! Realm()
        
        try! realm.write
        {
            note.lastEdited = formatter.string(from: Date())
            note.subChapterName = titlelabel
            
            if !note.savedToRealm
            {
                note.subChapterURL = uniqueAddress
                note.savedToRealm = true
                // Add new entry to Realm
                realm.add(note)
                // Save to the chapter
                content.notes.append(note)
            }
            // Add the content changes necessary to the tableview or refresh it if necessary, though I could maybe do this in another view and just throw it on top of this one, much like the protocols in HomeTown
            
        }
        if tableView.frame.isEmpty {
            loadTable()
        } else {
            tableView.reloadData()
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    func didDeleteNote( )
    {
        let realm = try! Realm()
        
        try! realm.write
        {
            realm.delete(note)
        }
        tableView.reloadData()
    }
    
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let searchViewController = segue.destination as? SearchViewController
        {
            searchViewController.size = CGRect.init(x: 0, y: 0, width: view.frame.width, height: 60)
        }
    }
}
