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
import Pendo

// MARK: - WebViewViewController Documentation
//
// ## Key Responsibilities:
//
// ## Key Components:
//
// ### WebView Configuration:
// - Custom WKWebView with JavaScript message handlers
// - Info icon click detection and tooltip display
// - Dynamic CSS injection for font scaling and icon sizing
// - Content loading and error handling
//
// ### UI Elements:
// - Search bar with in-page search functionality
// - Bookmark button with state management
// - Notes button with count display
// - Navigation bar with dynamic title configuration
//
// ### Integration Points:
// - Migrations.swift: Handles URL resolution for migrated content
// - ChapterIndex.swift: Provides content metadata and navigation structure
// - Realm database: Persists user data and content access
//
// ## Gotchas and Important Notes:
//
// ### URL Handling:
// - Internal links use custom navigation to stay within the app
// - External links require user confirmation before opening in Safari
// - Anchor links within the same page are handled differently than cross-page links
// - Migration paths must be considered for legacy bookmark URLs
//
// ### Performance Considerations:
// - Font scaling requires WebView reload with fade animation
//
/// WebViewViewController manages the Web View screen UI and interactions.
class WebViewViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, SaveFavoriteDelegate, SaveNoteDelegate, WKScriptMessageHandler, NotesBottomSheetDelegate, BookmarkSavedPopUpDelegate, NoteSavedPopUpDelegate,
    DeleteConfirmationPopUpDelegate {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var favoriteIcon: UIButton!
    
    @IBOutlet weak var search: UISearchBar!
    @IBOutlet weak var searchNavStackView: UIStackView!
    
    @IBOutlet weak var currentSearchTermIndex: UILabel!
    @IBOutlet weak var totalSearchTermsFound: UILabel!
    
	@IBOutlet var metadataView: UIView!

    @IBOutlet weak var viewNotesButton: UIButton!
    
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
    var userSettings: UserSettings?
    var fontNumber = 100
    
    /// Initialize the Realm database
    let realm = RealmHelper.sharedInstance.mainRealm()
//   let realm = try! Realm()
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
    
    private var searchTimer: Timer?
    
    var currentSearchResultIndex = 0
    var totalSearchResults = 0
    
    /// Primary setup method that configures the entire web view experience
    /// 
    /// This method orchestrates the complete initialization of the content display:
    /// 
    /// ### Setup Sequence:
    /// 1. **Search UI Configuration**: Shows/hides search bar based on navigation context
    /// 2. **WebView Creation**: Configures WKWebView with JavaScript message handlers for info icons
    /// 3. **Content Loading**: Loads the specified URL and sets up metadata
    /// 4. **User Settings**: Retrieves or creates user preferences for font size
    /// 5. **Analytics Integration**: Logs page views and tracks user interactions
    /// 6. **UI State**: Configures bookmark/notes buttons and navigation styling
    /// 
    /// ### JavaScript Integration:
    /// - Injects info icon click detection script
    /// - Sets up message handlers for tooltip display
    /// - Handles cross-page navigation and anchor links
    /// 
    /// ### Important Notes:
    /// - Special handling for coordinator appendix
    /// - Search bar visibility depends on `comingFromSearch` flag
    /// - Font size is loaded from UserSettings or defaults to 100%
    /// - Notes button shows count of existing notes for the content
    /// 
    /// - Warning: WebView configuration must happen before content loading
    /// - Warning: Analytics logging should use uniqueAddress for accurate tracking
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let searchTerm = searchTerm, comingFromSearch, !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            search.text = searchTerm
            let current = self.search.text ?? searchTerm
            
            /// Show immediately to avoid perceived delay
            self.searchNavStackView.isHidden = false
            self.searchNavStackView.alpha = 1
            self.searchNavStackView.transform = .identity
        } else {
            self.searchNavStackView.isHidden = true
        }
        
        configureSearchBar()
        
        metadataView.isHidden = true

		let filename = "15_appendix_district_tb_coordinators_(by_district).html"

        if url.lastPathComponent == filename {
            metadataView.isHidden = true
            metadataView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            metadataView.frame.size.height = 0
        }

        self.hidesBottomBarWhenPushed = true
                
        titleLabel.text = titlelabel
        dateLabel.text = "Updated \( chapterIndex.updateDate)"
        
        viewNotesButton.layer.cornerRadius = 15
        viewNotesButton.adjustsImageWhenHighlighted = false
        viewNotesButton.dropShadow()
        
        /// Create WebView Content
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        let infoIconScript = """
        (function() {
            if (window.__infoIconHandlerInstalled) { return; }
            window.__infoIconHandlerInstalled = true;
            document.addEventListener('click', function(event) {
                var el = event.target;
                if (!el) { return; }
                var info = el.closest ? el.closest('.info-icon') : null;
                if (!info) { return; }
                var tooltip = info.getAttribute('data-tooltip') || '';
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.infoIconTapped) {
                    window.webkit.messageHandlers.infoIconTapped.postMessage({ tooltip: tooltip });
                }
            }, true);
        })();
        """
        let userScript = WKUserScript(source: infoIconScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)
        userContentController.add(self, name: "infoIconTapped")
        config.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        setupUI()
        
        /// Log the page load
        Analytics.logEvent("page", parameters: [
            "page": (uniqueAddress ) as String,
        ])
        
        if let settings = getOrCreateUserSettings() {
            userSettings = settings
            fontNumber = settings.fontSize
        } else {
            userSettings = nil
            fontNumber = 100
        }
        
        if let notesCount = content?.notes.count {
            viewNotesButton.isHidden = false
            viewNotesButton.setTitle("(\(notesCount))", for: .normal)
        } else {
            viewNotesButton.isHidden = true
            viewNotesButton.setTitle("(0)", for: .normal)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(fontSizeChanged(_:)), name: NSNotification.Name("FontSizeChanged"), object: nil)
        webView.load( URLRequest( url: url ))
    }
    
    /// Safely retrieves or creates UserSettings with optional font size update
    /// 
    /// This method provides a centralized way to manage user preferences:
    /// 
    /// ### Behavior:
    /// 1. **Existing Settings**: Updates font size if provided, returns existing object
    /// 2. **New Settings**: Creates default UserSettings with optional font size
    /// 3. **Error Handling**: Returns nil if Realm operations fail
    /// 
    /// ### Font Size Management:
    /// - Persists font size changes immediately
    /// - Uses "savedSettings" as primary key for consistency
    /// - Handles write failures gracefully with error logging
    /// 
    /// ### Usage Context:
    /// - Called during viewDidLoad to load user preferences
    /// - Used during font size changes to persist new values
    /// - Provides fallback when settings are corrupted or missing
    /// 
    /// - Parameter fontSize: Optional font size to persist (0-200 range typical)
    /// - Returns: UserSettings object or nil if Realm operations fail
    /// 
    /// - Note: Font size changes are written immediately, not deferred
    private func getOrCreateUserSettings(with fontSize: Int? = nil) -> UserSettings? {
        guard let realm = realm else { return nil }
        if let existing = realm.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings") {
            if let fontSize = fontSize {
                do { try realm.write { existing.fontSize = fontSize } } catch { print("Failed to update existing UserSettings: \(error)") }
            }
            return existing
        }
        let newSettings = UserSettings()
        if let fontSize = fontSize { newSettings.fontSize = fontSize }
        do { try realm.write { realm.add(newSettings, update: .modified) } } catch { print("Failed to create UserSettings: \(error)") }
        return realm.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings")
    }
    
    /// Sets the navigation bar title and styling for content pages.
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
    
    /// Styles the in-page search bar to match app theme.
    func configureSearchBar() {
        guard let search = self.search, let textField = search.value(forKey: "searchField") as? UITextField else { return }

            /// Searchbar configuration
        textField.textColor = UIColor.searchBarText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter Keywords to Search",
            attributes: [.foregroundColor: UIColor.searchBarText]
        )
        textField.layer.cornerRadius = 60
        textField.backgroundColor = UIColor.searchBar

        textField.setSearchIcon(UIImage(named: "magnifyingGlass"), tintColor: UIColor.searchBarText)
        textField
            .setClearButton(UIImage(named: "icClear"), tintColor: UIColor.colorPrimary)
    }
    
    /// Handles font size change notifications from settings or user actions
    /// 
    /// This method responds to font size changes and updates the display:
    /// 
    /// ### Update Process:
    /// 1. **Persistence**: Saves new font size to UserSettings immediately
    /// 2. **UI Update**: Applies fade animation during WebView reload
    /// 3. **Content Refresh**: Reloads WebView to apply new CSS scaling
    /// 4. **Icon Scaling**: Triggers JavaScript injection for icon resizing
    /// 
    /// ### Animation Details:
    /// - WebView fades out (0.2s duration)
    /// - Content reloads with new font size
    /// - WebView fades back in automatically
    /// 
    /// ### Performance Considerations:
    /// - Reload is necessary for CSS media queries to take effect
    /// - Animation prevents visual flickering during reload
    /// - JavaScript injection happens after content loads
    /// 
    /// - Parameter notification: Contains "fontSize" key with new value (Int)
    /// 
    /// - Warning: WebView must be non-nil before attempting reload
    /// - Note: Font size range should be validated before calling this method
    @objc func fontSizeChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo, let newFontSize = userInfo["fontSize"] as? Int {
            fontNumber = newFontSize
            print("Changed the font size to \(fontNumber)")

            /// Always refetch to avoid creating duplicates
            if let settings = getOrCreateUserSettings(with: fontNumber) {
                userSettings = settings
            } else {
                print("Warning: Could not obtain UserSettings to persist font size")
            }

            guard webView != nil else { return }
            UIView.animate(withDuration: 0.20, animations: {
                self.webView.alpha = 0
            }) { _ in
                self.webView.reload()
            }
        }
    }
    
    /// Applies dynamic scaling to chapter icons and paragraph decorations
    /// 
    /// This method ensures visual elements scale proportionally with text size:
    /// 
    /// ### Scaling Targets:
    /// 1. **Chapter Icons**: SVG icons (ic_chapter.svg) resize with font percentage
    /// 2. **Paragraph Lines**: Decorative lines for .uk-paragraph class elements
    /// 3. **CSS Variables**: Sets --chapter-icon-size for responsive scaling
    /// 
    /// ### Scaling Logic:
    /// - Uses 125% as baseline (matches Android implementation)
    /// - Calculates scale factor: `fontSize / 125.0`
    /// - Applies scaling to width, height, and positioning
    /// 
    /// ### JavaScript Injection Strategy:
    /// 1. **CSS Variables**: Sets root-level CSS custom properties
    /// 2. **Class Tagging**: Adds .ic_chapter_icon class to relevant images
    /// 3. **Override Rules**: Injects !important CSS for guaranteed application
    /// 4. **Inline Styles**: Fallback sizing for pages without external CSS
    /// 5. **Paragraph Styling**: Scales decorative lines proportionally
    /// 
    /// ### Performance Notes:
    /// - Multiple JavaScript calls are executed with slight delays
    /// - DOM readiness is ensured before injection
    /// - Error handling prevents complete failure on individual script errors
    /// 
    /// - Parameter fontSize: Target font size percentage (typically 50-200)
    /// 
    /// - Important: Must be called after WebView content loads completely
    /// - Note: Scaling is cumulative with existing CSS sizing
    private func applyIconAndParagraphScaling(fontSize: Int) {
        /// Compute scale factor relative to 125% baseline (matching Android)
        let scaleFactor = Double(fontSize) / 125.0
        let iconPx = 24.0 * scaleFactor
        let iconPxStr = String(format: "%.2f", iconPx)
        
        /// Compute scaled metrics for the decorative line used by `.uk-paragraph`
        let remBasePx = 16.0 // 1rem baseline
        let ukHeightPx = 2.0 * remBasePx * scaleFactor      // was 2rem
        let ukWidthPx = 0.5 * remBasePx * scaleFactor       // was 0.5rem
        let ukTopPx = -0.25 * remBasePx * scaleFactor       // was -0.25rem
        let ukRadiusPx = 0.25 * remBasePx * scaleFactor     // was 0.25rem
        let ukHeightPxStr = String(format: "%.2f", ukHeightPx)
        let ukWidthPxStr = String(format: "%.2f", ukWidthPx)
        let ukTopPxStr = String(format: "%.2f", ukTopPx)
        let ukRadiusPxStr = String(format: "%.2f", ukRadiusPx)
        
        guard webView != nil else { return }
        
        /// 1) Set CSS variable consumed by .ic_chapter_icon in style.css (which uses !important)
        let setVar = """
            (function(){
                try {
                    var size='\(iconPxStr)px';
                    document.documentElement.style.setProperty('--chapter-icon-size', size);
                } catch(e) { console.log('Error setting CSS var:', e); }
            })();
        """
        
        /// 2) Ensure chapter icon image gets the class so the CSS rule applies, without touching other content images
        let tagIcons = """
            (function(){
                try {
                    var nodes = document.querySelectorAll('img[src$="ic_chapter.svg"], img[src*="/ic_chapter.svg"], img[src*="ic_chapter.svg"]');
                    console.log('Found', nodes.length, 'chapter icons');
                    nodes.forEach(function(n){
                        if(n.classList && !n.classList.contains('ic_chapter_icon')) n.classList.add('ic_chapter_icon');
                    });
                } catch(e) { console.log('Error tagging icons:', e); }
            })();
        """
        
        /// 3) Inject an explicit override rule with !important placed after external CSS
        let injectOverride = """
            (function(){
                 try {
                     var style = document.getElementById('chapter-icon-override');
                     if(!style){
                         style = document.createElement('style');
                         style.id = 'chapter-icon-override';
                         document.head.appendChild(style);
                     }
                     var size='\(iconPxStr)px';
                     style.textContent = '.ic_chapter_icon{width:'+size+' !important;height:'+size+' !important;}';
                     console.log('Injected icon override style:', size);
                 } catch(e) { console.log('Error injecting override:', e); }
            })();
        """
        
        /// 4) Also apply inline size and attributes so pages missing style.css still resize correctly
        let sizeIcons = """
            (function(){
                 try {
                     var cssSize='\(iconPxStr)px';
                     var attrSize='\(iconPxStr)';
                     var nodes = document.querySelectorAll('img[src$="ic_chapter.svg"], img[src*="/ic_chapter.svg"], img[src*="ic_chapter.svg"]');
                     console.log('Sizing', nodes.length, 'icons to', cssSize);
                     nodes.forEach(function(n){
                         /// Ensure the parent wrapper also reserves space for the icon
                         var p = n.parentElement;
                         if (p) {
                             p.style.width = cssSize;
                             p.style.height = cssSize;
                             p.style.flex = '0 0 auto';
                         }
                         /// Apply explicit sizing on the image
                         n.style.display = 'inline-block';
                         n.style.width = cssSize;
                         n.style.height = cssSize;
                         n.style.maxWidth = cssSize;
                         n.style.maxHeight = cssSize;
                         if (n.setAttribute) {
                             n.setAttribute('width', attrSize);
                             n.setAttribute('height', attrSize);
                         }
                     });
                 } catch(e) { console.log('Error sizing icons:', e); }
            })();
        """
        
        /// 5) Scale the decorative line for paragraphs `.uk-paragraph::before` to match text zoom
        let paragraphOverride = """
            (function(){
                 try {
                     var style = document.getElementById('uk-paragraph-override');
                     if(!style){
                         style = document.createElement('style');
                         style.id = 'uk-paragraph-override';
                         document.head.appendChild(style);
                     }
                     var h='\(ukHeightPxStr)px';
                     var w='\(ukWidthPxStr)px';
                     var t='\(ukTopPxStr)px';
                     var r='\(ukRadiusPxStr)px';
                     style.textContent = ''+
                       '.uk-paragraph{position: relative;}'+
                       '.uk-paragraph::before{'+
                         'content:""; position:absolute; left:0; '+
                         'top:'+t+' !important; '+
                         'height:'+h+' !important; '+
                         'width:'+w+' !important; '+
                         'background-color: var(--primary-color); '+
                         'border-radius:'+r+' !important;'+
                       '}';
                     console.log('Applied paragraph override');
                 } catch(e) { console.log('Error with paragraph override:', e); }
            })();
        """
        
        /// Execute all JavaScript on the WebView with a small delay to ensure DOM is ready
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            guard let self = self else { return }
            
            self.webView.evaluateJavaScript(setVar) { result, error in
                if let error = error {
                    print("setVar error: \(error)")
                }
            }
            
            self.webView.evaluateJavaScript(tagIcons) { result, error in
                if let error = error {
                    print("tagIcons error: \(error)")
                }
            }
            
            self.webView.evaluateJavaScript(injectOverride) { result, error in
                if let error = error {
                    print("injectOverride error: \(error)")
                }
            }
            
            self.webView.evaluateJavaScript(sizeIcons) { result, error in
                if let error = error {
                    print("sizeIcons error: \(error)")
                }
            }
            
            self.webView.evaluateJavaScript(paragraphOverride) { result, error in
                if let error = error {
                    print("paragraphOverride error: \(error)")
                }
            }
        }
    }
        
    /// Removes observers to avoid leaks.
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("FontSizeChanged"), object: nil)
        try? webView?.removeObserver(self, forKeyPath: "URL")
    }
    
    /// Helper to resolve the parent chapter title from uniqueAddress via ChapterIndex
    /// Maps a content slug to its parent chapter title using ChapterIndex.
    private func resolvedChapterParent(for code: String?) -> String {
        guard let code = code, !code.isEmpty else { return navTitle }
        /// Strip any anchor
        let baseCode = code.components(separatedBy: "#").first ?? code
        let flatCodes = Array(chapterIndex.chapterCode.joined())
        if let idx = flatCodes.firstIndex(of: baseCode),
           idx < chapterIndex.chaptermapsubchapter.count {
            return chapterIndex.chaptermapsubchapter[idx]
        }
        /// Fallback to navTitle to avoid empty UI if mapping not found
        return navTitle
    }
    
    /// Ensures content history, favorites, and notes are up to date:
    /// - Creates/updates ContentPage and ContentAccess entries
    /// - Updates bookmark/notes UI state
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        setupNavBar()
        
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
            /// Set chapterParent using ChapterIndex mapping (not navTitle)
            content.chapterParent = resolvedChapterParent(for: uniqueAddress)
            content.lastOpened = Date()
            content.openedTimes += 1
            RealmHelper.sharedInstance.save(content) { saved in
                ///
            }
        }
        
        /// Save recently viewed chapters list
        let lastAccessed  = realm!.objects(ContentAccess.self)
        /// This determines the buffer that we are allowing
        if lastAccessed.count > 7 {
            RealmHelper.sharedInstance.delete(lastAccessed[0]) { deleted in
                ///
            }
        }
        
        
        /// Save history
        if lastAccessed.filter("url == '\(content.url)'").count == 0 {
            print("Thinks history is false")
            let currentAccessedContent = ContentAccess()
            currentAccessedContent.name = titlelabel
            currentAccessedContent.url = uniqueAddress
            /// Set chapterParent using ChapterIndex mapping (not navTitle)
            currentAccessedContent.chapterParent = resolvedChapterParent(for: uniqueAddress)
            currentAccessedContent.date = Date()
            RealmHelper.sharedInstance.save(currentAccessedContent) { [weak self] saved in
                ///
                RealmHelper.sharedInstance.update(self!.content, properties: [
                    "isHistory": true
                ]) { [weak self] updated in
                    ///
                }
            }
            
        } else {
            /// Should move entry to the top of the history list...
            let newAccessed = lastAccessed.filter("url == '\(content.url)'")
            RealmHelper.sharedInstance.update(newAccessed[0], properties: [
                "date": Date()
            ]) { [weak self] updated in
                ///
            }
            
        }
        
        
        if content.favorite == true {
            favoriteIcon.setImage(UIImage(named: "icBookmarksFolderColored"), for: .normal)
            favoriteIcon.setAttributedTitle(bookmarkedText, for: .normal)
        }
        
        updateNotesButton()
    }
    
    /// Hooks URL observation and refreshes bookmark/notes UI state.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        /// This removes the favoriting if it gets deleted in the saved page
        if content.favorite == false {
            favoriteIcon.setImage(UIImage(named: "icBookmarksFolder"), for: .normal)
            favoriteIcon.setAttributedTitle(bookmarkText, for: .normal)
        }
        
        /// Add observer to the WebView so that when the URL changes it triggers our detection function
        webView.addObserver(self, forKeyPath: "URL", options: [.new, .old], context: nil)
        
        updateNotesButton()
    }
    
    /// Resets the web view when leaving the screen.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(false)
        
        webView?.goBack()
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Intercepts in-app link navigation:
    /// - Pushes internal pages into a new WebViewViewController
    /// - Confirms external links before opening Safari
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let newValue = change?[.newKey] as? Int, let oldValue = change?[.oldKey] as? Int, newValue != oldValue {
            /// Value Changed
            /// .components(separatorBy: ".app/")
            print("new key is ",change?[.newKey] ?? "Couldn't print the new key")
        }else{
            ///Value not Changed
            print("old key is ",change?[.oldKey] ?? "Couldn't print the old key")
        }

        /// Find the actual string
        /// When you click a link that becomes the new key
        /// Even if the page doesn't change because you had it blocked, the new link becomes the old link, so I want to put a checker condition that only when both links come from within the app you should go through this function
        if let newValue = change?[.newKey], (newValue as AnyObject).debugDescription.hasPrefix("file:///"), let oldValue = change?[.oldKey], (oldValue as AnyObject).debugDescription.hasPrefix("file:///"){
            let newURL = change?[.newKey].debugDescription.components(separatedBy: "GA-TB-Reference-Guide.app/")[1] ?? "Couldn't print the new key"
            print("Loading within the app content", newURL)
            /// Check if we are not going into a within page anchor link or we came from an anchor link and it's resetting the view regardless
            let oldURL = change?[.oldKey].debugDescription.components(separatedBy: "GA-TB-Reference-Guide.app/")[1] ?? "Couldn't print the old key"
            print(newURL)
            print(oldURL)
            if (!newURL.contains("#") /*&& !oldURL.contains("#")*/) || oldURL.hasPrefix("table_"){
                
                let urlsarray = Array(chapterIndex.chapterCode.joined()).firstIndex(of: newURL.components(separatedBy: ".")[0])
                
                /// push view controller but animate modally
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyBoard.instantiateViewController(withIdentifier: "web") as! WebViewViewController

                let navigationController = self.navigationController
                
                /// If there is an anchor present we want to take the user to that position on the file
                if newURL.contains("#"){
                    let anchor = "#"+newURL.components(separatedBy: "#")[1].replacingOccurrences(of: ")", with: "")
                    print("this is the anchor", anchor)
                    let baseURL = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0], withExtension: "html")!
                    vc.url = URL(string: anchor, relativeTo: baseURL)
                } else {
                    vc.url = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0], withExtension: "html")!
                }
                vc.titlelabel = Array(chapterIndex.chapterNested.joined())[urlsarray ?? 0]
                vc.navTitle = chapterIndex.chaptermapsubchapternested[urlsarray ?? 0]
                vc.uniqueAddress = Array(chapterIndex.chapterCode.joined())[urlsarray ?? 0]
                
                /// Remove the observer for the previous screen so that it won't double fire when the URL changes again
                try? webView?.removeObserver(self, forKeyPath: "URL")

                navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            print("Loading outside of the app content")
            /// newURL stays as the chapter because the webview stopsloading
            
            /// This has been added to optionally cast to a URL in the event that the devices observer was obsolete from a previous load
            if let oldURL = change?[.oldKey] as? URL {
                
                ///            let newURL = change?[.newKey] as! URL
                ///            let oldURL = change?[.oldKey] as! URL
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
                
                /// Remove the observer for the previous screen so that it won't double fire when the URL changes again
                ///            webView.removeObserver(self, forKeyPath: "URL")
                ///            UIApplication.shared.open(newURL, options: Any, completionHandler: true)
                ///            webView.goBack()
            }
        }
    }
    
    /// This function is just preventing the within the app pages to move to the web links because there is no new page that we need to call the goBack() function from
    /// Central navigation policy handler for all WebView navigation requests
    /// 
    /// This method is the gatekeeper for all link navigation within the WebView:
    /// 
    /// ### Navigation Types Handled:
    /// 
    /// **1. Initial Page Load (.other/.reload)**:
    /// - Always allowed for initial content loading
    /// - No user interaction required
    /// 
    /// **2. Internal App Links (file:// URLs)**:
    /// - Extracts filename from app bundle path
    /// - Distinguishes between anchor links and cross-page navigation
    /// - Anchor links within same page: Allow navigation (scroll to position)
    /// - Cross-page links: Cancel WebView navigation, push new controller
    /// 
    /// **3. External Links (.linkActivated)**:
    /// - Shows confirmation dialog before opening in Safari
    /// - Prevents accidental external navigation
    /// - Maintains user within app ecosystem by default
    /// 
    /// ### Cross-Page Navigation Process:
    /// 1. Cancel WebView's default navigation
    /// 2. Extract target filename from URL
    /// 3. Look up content metadata in ChapterIndex
    /// 4. Create new WebViewViewController with proper configuration
    /// 5. Handle anchor links if present (scroll to specific section)
    /// 6. Push new controller onto navigation stack
    /// 
    /// ### Security Considerations:
    /// - All external links require explicit user confirmation
    /// - Internal links are validated against known content
    /// - Malformed URLs are safely handled with fallback behavior
    /// 
    /// - Parameters:
    ///   - webView: The WebView making the navigation request
    ///   - navigationAction: Contains navigation details and target URL
    ///   - decisionHandler: Callback to allow or cancel navigation
    /// 
    /// - Warning: Always call decisionHandler exactly once
    /// - Note: This method is called for every navigation attempt
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        let urlString = url.absoluteString
        
        /// Allow initial page load
        if navigationAction.navigationType == .other || navigationAction.navigationType == .reload {
            decisionHandler(.allow)
            return
        }
        
        /// Handle internal app links (file:// URLs)
        if urlString.hasPrefix("file:///") {
            /// Extract the filename
            let components = urlString.components(separatedBy: "GA-TB-Reference-Guide.app/")
            guard components.count > 1 else {
                decisionHandler(.allow)
                return
            }
            
            let newURL = components[1]
            
            /// Check if it's an anchor link within the same page
            if newURL.contains("#") {
                let baseFile = newURL.components(separatedBy: "#")[0]
                let currentFile = self.url.lastPathComponent
                
                /// If it's the same file, allow navigation (anchor scroll)
                if baseFile == currentFile || baseFile.isEmpty {
                    decisionHandler(.allow)
                    return
                }
            }
            
            /// It's a different page - handle custom navigation
            /// Cancel the WebView's navigation
            decisionHandler(.cancel)
            
            /// Find the chapter index
            let fileName = newURL.components(separatedBy: ".")[0].components(separatedBy: "#")[0]
            guard let urlsarray = Array(chapterIndex.chapterCode.joined()).firstIndex(of: fileName) else {
                return
            }
            
            /// Create and push new view controller
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            guard let vc = storyBoard.instantiateViewController(withIdentifier: "web") as? WebViewViewController else {
                return
            }
            
            /// Configure the new view controller
            if newURL.contains("#") {
                let anchor = "#" + newURL.components(separatedBy: "#")[1].replacingOccurrences(of: ")", with: "")
                let baseURL = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[urlsarray], withExtension: "html")!
                vc.url = URL(string: anchor, relativeTo: baseURL)
            } else {
                vc.url = Bundle.main.url(forResource: Array(chapterIndex.chapterCode.joined())[urlsarray], withExtension: "html")!
            }
            
            vc.titlelabel = Array(chapterIndex.chapterNested.joined())[urlsarray]
            vc.navTitle = chapterIndex.chaptermapsubchapternested[urlsarray]
            vc.uniqueAddress = Array(chapterIndex.chapterCode.joined())[urlsarray]
            
            /// Push the view controller
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        /// Handle external links
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            
            let alertDelete = UIAlertController(
                title: "This link will open in your browser, do you want to continue?",
                message: "",
                preferredStyle: .alert
            )
            
            alertDelete.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            
            alertDelete.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            present(alertDelete, animated: true)
            return
        }
        
        /// Default: allow navigation
        decisionHandler(.allow)
    }
    
    /// Runs JS search logic and aggregates hit counts across terms.
    func searchAndCountWords(term: String) {
        var terms = term.split(separator: " ").map({String($0)})
        if !terms.contains(term) {terms.append(term)}
        
        if let path = Bundle.main.url(forResource: "WebView", withExtension: "js") {
            do {
                let data: Data = try Data(contentsOf: path)
                let jsCode: String = String(decoding: data, as: UTF8.self)
                
                /// Inject the search code
                webView.evaluateJavaScript(jsCode, completionHandler: nil)
                
                /// Count total words found across all search terms
                var totalWordCount = 0
                let dispatchGroup = DispatchGroup()
                
                for (i, t) in terms.enumerated() {
                    dispatchGroup.enter()
                    
                    /// Modified search string to return count
                    let searchString = "WKWebView_HighlightAllOccurencesOfString('\(t)', \(i == 0))"
                    
                    /// Perform search and get count
                    webView.evaluateJavaScript(searchString) { [weak self] (result, error) in
                        defer { dispatchGroup.leave() }
                        
                        if let error = error {
                            print("Error searching for '\(t)': \(error)")
                            return
                        }
                        
                        /// If your WebView.js returns the count, use it
                        if let count = result as? Int {
                            totalWordCount += count
                        }
                    }
                }
                
                /// When all searches are complete, print the total count
                dispatchGroup.notify(queue: .main) {
                    print("Total words found: \(totalWordCount)")
                }
                
            } catch {
                print("Could not load javascript: \(error)")
            }
        }
    }
    
    /// Updates the UI counters for in-page search navigation.
    func updateSearchResultsDisplay() {
        currentSearchTermIndex.text = "\(currentSearchResultIndex)"
        totalSearchTermsFound.text = "\(totalSearchResults)"
        
        // Show/hide navigation if there are results
//        searchNavStackView.isHidden = totalSearchResults == 0
    }
    
    /// Highlights matches and updates the total hit count.
    func highlightSearchWithCount(term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            removeHighlights()
            searchNavStackView.isHidden = true
            totalSearchResults = 0
            currentSearchResultIndex = 0
            updateSearchResultsDisplay()
            return
        }
        if let path = Bundle.main.url(forResource: "WebView", withExtension: "js") {
            do {
                let data: Data = try Data(contentsOf: path)
                let jsCode: String = String(decoding: data, as: UTF8.self)
                webView.evaluateJavaScript(jsCode, completionHandler: nil)

                let escaped = trimmed.replacingOccurrences(of: "'", with: "\\'")
                let searchString = "WKWebView_HighlightAllOccurencesOfStringWithNavigation('\(escaped)', true)"
                webView.evaluateJavaScript(searchString) { [weak self] (result, error) in
                    if let count = result as? Int {
                        self?.totalSearchResults = count
                        self?.currentSearchResultIndex = count > 0 ? 1 : 0
                        DispatchQueue.main.async {
                            self?.searchNavStackView.isHidden = count == 0
                            self?.updateSearchResultsDisplay()
                        }
                    }
                }
            } catch {
                print("Could not load javascript: \(error)")
            }
        }
    }
    
    
    /// Moves the web view to the previous highlighted match.
    @IBAction func goToPreviousSearchTerm(_ sender: Any) {
        webView.evaluateJavaScript("WKWebView_GoToPreviousSearchResult()") { [weak self] (result, error) in
            if let success = result as? Bool, success {
                /// Get updated search info
                self?.webView.evaluateJavaScript("WKWebView_GetSearchInfo()") { (infoResult, infoError) in
                    if let infoDict = infoResult as? [String: Any],
                       let currentPosition = infoDict["currentPosition"] as? Int {
                        DispatchQueue.main.async {
                            self?.currentSearchResultIndex = currentPosition
                            self?.updateSearchResultsDisplay()
                        }
                    }
                }
            }
        }
    }
    
    /// Moves the web view to the next highlighted match.
    @IBAction func goToNextSearchTerm(_ sender: Any) {
        webView.evaluateJavaScript("WKWebView_GoToNextSearchResult()") { [weak self] (result, error) in
            if let success = result as? Bool, success {
                /// Get updated search info
                self?.webView.evaluateJavaScript("WKWebView_GetSearchInfo()") { (infoResult, infoError) in
                    if let infoDict = infoResult as? [String: Any],
                       let currentPosition = infoDict["currentPosition"] as? Int {
                        DispatchQueue.main.async {
                            self?.currentSearchResultIndex = currentPosition
                            self?.updateSearchResultsDisplay()
                        }
                    }
                }
            }
        }
    }
    
    
    /// Presents the notes bottom sheet for the current page.
    @IBAction func viewNotesTapped(_ sender: Any) {
        _ = UIStoryboard(name: "Main", bundle: nil)
            
            /// If you're using storyboard, create the identifier in storyboard and uncomment this:
            /// let notesVC = storyboard.instantiateViewController(withIdentifier: "NotesBottomSheetViewController") as! NotesBottomSheetViewController
            
            /// If creating programmatically, use this:
            let notesVC = NotesBottomSheetViewController()
            
            notesVC.content = self.content
            notesVC.delegate = self
            
            /// Configure the presentation style for bottom sheet
        if #available(iOS 15.0, *) {
            if let sheet = notesVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
        } else {
            /// Fallback on earlier versions
        }
            
            present(notesVC, animated: true)
    }
    

    ///--------------------------------------------------------------------------------------------------
    /// Opens the bookmark dialog to save or update a favorite.
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
    
    ///--------------------------------------------------------------------------------------------------
    /// Creates a new note for this page.
    @IBAction func addNote(_ sender: UIButton){
        openNoteWindow(noteChosen: Notes())
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Returns to the root screen.
    @IBAction func backToHomepage(_ sender: UIButton){
        navigationController?.popToRootViewController(animated: true)
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Builds a Firebase Dynamic Link and presents the share sheet.
    @IBAction func shareContent(_ sender: UIButton){
        /// Add activity indicator if using short link
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "apphatcherygatbreferenceguide.page.link"
        components.path = "/share"
        
        let chapterIDQueryItem = URLQueryItem(name: "chapterId", value: uniqueAddress)
        let isChartQueryItem = URLQueryItem(name: "androidIsPage", value: uniqueAddress.contains("table") ? "0" : "1")
        components.queryItems = [chapterIDQueryItem,isChartQueryItem]
        
        guard let linkParameter = components.url else { return }
        print("I am sharing \(linkParameter.absoluteString)")
        
        /// Dynamic Link
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
        
        /// Sets a drawback because it's slow, so we might make it long and that's it
        shareLink.shorten { [weak self] url, warnings, error in
            if let error = error {
                print("Got an error shortening the dynamic link \(error)")
                /// If for any reason the link shortening doesn't work, then send the long link URL
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
    
    /// Presents the share sheet and handles "copy link" feedback UI.
    func shareChapter(url: URL){
        // This is text to accompany the
//        let promoText = "Check out this subchapter of the TB Reference Guide "
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        activityVC.completionWithItemsHandler = {
            [weak self] activityType, completed, _, _ in
            
            guard completed, activityType == .copyToPasteboard else { return }
            
            if let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .first as? UIWindowScene,
               let window = windowScene.windows.first(
                where: { $0.isKeyWindow
                }) {
                CustomPopUp
                    .showTemporary(in: window, popupLabelText: "Link Copied")
            } else {
                let alert = UIAlertController(
                    title: "Link Copied",
                    message: nil,
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true)
            }
        }
        present(activityVC, animated: true)
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Opens the font settings popover.
    @IBAction func fontSettings(_ sender: UIButton) {
        let popUpOverlay = FontSettingsView()
        popUpOverlay.displayPopUp(sender:self)
    }
    
    /// Highlights terms in the web view without updating navigation counters.
    func highlightSearch(term: String) {
        var terms = term.split(separator: " ").map({String($0)})
        if !terms.contains(term) {terms.append(term)}
        
        if let path = Bundle.main.url(forResource: "WebView", withExtension: "js") {
            do {
                let data: Data = try Data(contentsOf: path)
                let jsCode: String = String(decoding: data, as: UTF8.self)
                
                /// Inject the search code
                webView.evaluateJavaScript(jsCode, completionHandler: nil)
                
                /// Use navigation-enabled function for primary term
                let searchString = "WKWebView_HighlightAllOccurencesOfStringWithNavigation('\(terms[0])', true)"
                webView.evaluateJavaScript(searchString) { [weak self] (result, error) in
                    if let count = result as? Int {
                        self?.totalSearchResults = count
                        self?.currentSearchResultIndex = count > 0 ? 1 : 0
                        
                        DispatchQueue.main.async {
                            self?.updateSearchResultsDisplay()
                        }
                    }
                }
                
                /// Highlight additional terms with original function
                for i in 1..<terms.count {
                    let additionalSearchString = "WKWebView_HighlightAllOccurencesOfString('\(terms[i])', false)"
                    webView.evaluateJavaScript(additionalSearchString, completionHandler: nil)
                }
                
            } catch {
                print("Could not load javascript: \(error)")
            }
        }
    }
    
    /// Clears all in-page highlight markers.
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
    
    ///--------------------------------------------------------------------------------------------------
    /// Injects CSS/JS, applies font scaling, and syncs search highlights after load.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let urlHeader = webView.url?.absoluteString, urlHeader.hasPrefix("file:///"){
            
            let path = Bundle.main.path(forResource: "uikit", ofType: "css")!
            /// This converts a multiline string into a single file, the .whitespacesandNewlines doesn't work to do that job
            let cssString = try! String(contentsOfFile: path).replacingOccurrences(of: "\n", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
            
            let path2 = Bundle.main.path(forResource: "style", ofType: "css")!
            let cssString2 = try! String(contentsOfFile: path2).replacingOccurrences(of: "\n", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
            /// Could potentially replace this with just the link to the file rather than having to convert it to string, save some computational power
            let jsString2 = "var style2 = document.createElement('style'); style2.innerHTML = '\(cssString2)'; document.head.appendChild(style2);"
            
            let js3 = "var script2 = document.createElement('script'); script2.src = 'uikit-icons.js'; document.body.appendChild(script2);"
            webView.evaluateJavaScript(jsString2, completionHandler: nil)
            webView.evaluateJavaScript(js3, completionHandler: nil)
            
            UIView.animate(withDuration: 0.20) {
                self.webView.alpha = 1
            }
            
            /// Sync fontNumber from latest UserSettings before applying CSS
            if let settings = realm?.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings") {
                userSettings = settings
                fontNumber = settings.fontSize
            }

            /// Apply font size - this sets the text zoom
            let textSize = fontNumber >= 75 ? fontNumber : 100
            let javascript = "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(textSize)%'"
            webView.evaluateJavaScript(javascript) { (response, error) in
                print()
            }
            
            /// AUTO-EXPAND TOGGLES WHEN COMING FROM SEARCH
            expandAllToggles()
            
            if let searchTerm = searchTerm, comingFromSearch {
                /// Use exact current text if available
                let term = (self.search.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? (self.search.text ?? searchTerm) : searchTerm
                self.highlightSearchWithCount(term: term)

                /// Direct, immediate call to jump to first result (no delay)
                self.webView.evaluateJavaScript("WKWebView_GetSearchInfo()") { [weak self] (infoResult, infoError) in
                    guard let self = self else { return }
                    if let infoDict = infoResult as? [String: Any], let total = infoDict["totalResults"] as? Int {
                        self.totalSearchResults = total
                        if total > 0 {
                            self.currentSearchResultIndex = 1
                            self.searchNavStackView.isHidden = false
                            self.updateSearchResultsDisplay()
                            self.webView.evaluateJavaScript("WKWebView_GoToNextSearchResult()", completionHandler: nil)
                        } else {
                            self.currentSearchResultIndex = 0
                            self.searchNavStackView.isHidden = true
                            self.updateSearchResultsDisplay()
                        }
                    } else {
                        /// Fallback: still try to move to first result
                        self.webView.evaluateJavaScript("WKWebView_GoToNextSearchResult()", completionHandler: nil)
                        self.currentSearchResultIndex = max(1, self.currentSearchResultIndex)
                        self.searchNavStackView.isHidden = false
                        self.updateSearchResultsDisplay()
                    }
                }
            }
            
            else if let searchTerm = searchTerm {
                highlightSearch(term: searchTerm)
            }
            
            applyIconAndParagraphScaling(fontSize: fontNumber)
            
        } else {
            print("outside the app, don't apply styling")
        }
    }
    
    /// Receives JS events (e.g., info icon taps) for analytics tracking.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "infoIconTapped" else { return }
        let tooltip: String = {
            if let dict = message.body as? [String: Any],
               let value = dict["tooltip"] as? String {
                return value
            }
            return ""
        }()
        
        PendoManager.shared().track("infoIconTapped", properties: [
            "page_url": uniqueAddress ?? "",
            "page_title": navTitle,
            "tooltip": tooltip
        ])
        print("Pendo infoIconTapped:", [
            "page_url": uniqueAddress ?? "",
            "page_title": navTitle,
            "tooltip": tooltip
        ])
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Lays out the web view inside the content container.
    func setupUI() {
        guard contentView != nil, webView != nil else { return }
//        self.view.backgroundColor = .white
        contentView.addSubview(webView)
        
        webViewTopConstraint = webView.topAnchor
            .constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor)
        
        NSLayoutConstraint.activate([
            webViewTopConstraint,
             webView.leftAnchor
                .constraint(equalTo: contentView.leftAnchor, constant: 10),
            webView.bottomAnchor
                .constraint(equalTo: contentView.bottomAnchor),
            webView.rightAnchor
                .constraint(equalTo: contentView.rightAnchor, constant: -10)
        ])
         
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Persists a bookmark name and updates UI/analytics.
    func didSaveName( _ name: String)
    {
        let bookmarkedText = NSAttributedString(
            string: "Bookmarked",
            attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 9.0)
            ]
        )
        
        /// let realm = try! Realm()
        
        let trimmedParent = content.chapterParent.trimmingCharacters(in: .whitespacesAndNewlines)
        var updateProperties: [String: Any] = [
            "favoriteName": name,
            "favorite": true
        ]
        if trimmedParent.isEmpty, let resolvedParent = resolvedChapterParentForBookmark(for: uniqueAddress) {
            updateProperties["chapterParent"] = resolvedParent
        }

        RealmHelper.sharedInstance.update(content, properties: updateProperties) { [weak self] updated in
            ///
            self?.favoriteIcon.setImage(UIImage(named: "icBookmarksFolderColored"), for: .normal)
            self?.favoriteIcon.setAttributedTitle(bookmarkedText, for: .normal)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? SceneDelegate,
               let window = sceneDelegate.window {
                
                BookmarkSavedPopUp.show(
                    in: window,
                    bookmarkName: name,
                    delegate: self
                )
            }
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
    
    /// Resolves the parent chapter title for a bookmark (charts and chapters).
    private func resolvedChapterParentForBookmark(for slug: String?) -> String? {
        guard let slug = slug, !slug.isEmpty else { return nil }
        let baseSlug = slug.components(separatedBy: "#").first ?? slug

        let chartCodes = Array(chapterIndex.chartCode.joined())
        if let idx = chartCodes.firstIndex(of: baseSlug) {
            let chartNested = Array(chapterIndex.chartNested.joined())
            if chartNested.indices.contains(idx) {
                return chartNested[idx]
            }
        }

        let chapterCodes = Array(chapterIndex.chapterCode.joined())
        if let idx = chapterCodes.firstIndex(of: baseSlug),
           chapterIndex.chaptermapsubchapternested.indices.contains(idx) {
            return chapterIndex.chaptermapsubchapternested[idx]
        }

        return nil
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Confirms and deletes an existing favorite.
    func didRemoveFavorite() {
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let sceneDelegate = windowScene.delegate as! SceneDelegate
        
        if let window = sceneDelegate.window {
            DeleteConfirmationPopUp.show(
                in: window,
                bookmarkName: content.favoriteName,
                delegate: self
            )
        }
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Saves or updates a note tied to the current page.
    func didSaveNote(_ note: Notes) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/YYYY"
        
        if !note.savedToRealm {
            RealmHelper.sharedInstance.update(note, properties: [
                "subChapterURL": uniqueAddress ?? "",
                "savedToRealm": true,
                "lastEdited": formatter.string(from: Date()),
                "subChapterName": titlelabel
            ]) { updated in
                ///
                RealmHelper.sharedInstance.appendNote(self.content, property: self.content.notes, itemToAppend: self.note) { appended in
                    print("appended the note properly?")
                }
                
                self.updateNotesButton()
            }
        } else {
            RealmHelper.sharedInstance.update(note, properties: [
                "lastEdited": formatter.string(from: Date()),
                "subChapterName": titlelabel
            ]) { updated in
                ///
            }
        }
    }
    
    /// Saves a note and optionally submits it as feedback.
    func didSaveNote(_ note: Notes, shouldSubmitAsFeedback: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/YYYY"
        
        if !note.savedToRealm {
            RealmHelper.sharedInstance.update(note, properties: [
                "subChapterURL": uniqueAddress ?? "",
                "savedToRealm": true,
                "lastEdited": formatter.string(from: Date()),
                "subChapterName": titlelabel
            ]) { [weak self] updated in
                guard let self = self else { return }
                
                RealmHelper.sharedInstance.appendNote(self.content, property: self.content.notes, itemToAppend: note) { appended in
                    print("appended the note properly?")
                }
                
                self.updateNotesButton()
                
                /// Track note save with feedback flag
                PendoManager.shared().track("user_feedback_submitted", properties: [
                    "page_url": self.uniqueAddress ?? "",
                    "page_title": self.titlelabel
                ])
                
                if shouldSubmitAsFeedback {
                    self.submitNoteAsFeedback(note)
                }
            }
        } else {
            RealmHelper.sharedInstance.update(note, properties: [
                "lastEdited": formatter.string(from: Date()),
                "subChapterName": titlelabel
            ]) { [weak self] updated in
                guard self != nil else { return }
                
            }
        }
    }
    
    /// Tracks feedback submission and shows confirmation UI.
    private func submitNoteAsFeedback(_ note: Notes) {
        PendoManager.shared().track("user_feedback_submitted", properties: [
            "feedback_content": note.content,
            "page_url": uniqueAddress ?? "",
            "page_title": titlelabel,
        ])
        
        print("Submitting note as feedback: \(note.content)")
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            
            NoteSavedPopUp.show(in: window, delegate: self)
        }
        
        /// Track Firebase analytics as well
        Analytics.logEvent("feedback_submitted", parameters: [
            "page": uniqueAddress as String,
            "content_length": note.content.count,
            "chapter": navTitle
        ])
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Deletes a note and updates the notes badge UI.
    func didDeleteNote(_ note: Notes) {
        RealmHelper.sharedInstance.delete(note) { [weak self] deleted in
            self?.updateNotesButton()
        }
    }
    
    
    ///--------------------------------------------------------------------------------------------------
    /// Passes sizing info when navigating to search.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let searchViewController = segue.destination as? SearchViewController
        {
            searchViewController.size = CGRect.init(x: 0, y: 0, width: view.frame.width, height: 60)
        }
    }
    
    ///--------------------------------------------------------------------------------------------------
    /// Collapses and removes the embedded table view UI.
    func removeTable()
    {
        UIView.animate(withDuration: 0.3, delay: 0.01, options: .curveLinear, animations: {
            self.tableView.frame.size.height = 0
//            self.separatorHeightConstraint = self.pseudoseparator.heightAnchor.constraint(equalToConstant: 0.5)
//            self.separatorHeightConstraint.isActive = true
            self.view.layoutIfNeeded()
        }, completion: { finished in
            self.tableView.removeFromSuperview()
            self.tableButton.removeFromSuperview()
            self.tableSeparator.removeFromSuperview()
            self.webViewTopConstraint.constant = 0.5
        })
    }
    
    /// Presents the note editor overlay for a new or existing note.
    func openNoteWindow(noteChosen: Notes)
    {
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let sceneDelegate = windowScene.delegate as! SceneDelegate
        
        if let window = sceneDelegate.window
        {
            /// Need to feed in here the note that you tap on, otherwise feed in a totally new note
            /// Look at the sender, either the UIButton or the UITableViewCell
            addNoteDialogView = SaveNote( frame: window.bounds, content: content, oldNote: noteChosen, delegate: self )
            note = noteChosen
            addNoteDialogView.contentView.transform = CGAffineTransform( scaleX: 0, y: 0 )
            addNoteDialogView.overlayView.alpha = 0
                        
            window.addSubview( addNoteDialogView )
            
            UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                self.addNoteDialogView.overlayView.alpha = 0.5
                self.addNoteDialogView.contentView.transform = CGAffineTransform( scaleX: 1.0, y: 1.0 )
            }, completion: { (value: Bool) in
                
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
    
    /// Presents the feedback form overlay for the current page.
    func openFeedbackWindow(parent: String, title: String)
    {
        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
        let sceneDelegate = windowScene.delegate as! SceneDelegate
        
        if let window = sceneDelegate.window
        {
            /// Need to feed in here the note that you tap on, otherwise feed-in a totally new note
            /// Look at the sender, either the UIButton or the UITableViewCell
            addFeedbackDialogView = FeedbackForm( frame: window.bounds, parent: parent, title: title )
            
            addFeedbackDialogView.contentView.transform = CGAffineTransform( scaleX: 0, y: 0 )
            addFeedbackDialogView.overlayView.alpha = 0
                        
            window.addSubview( addFeedbackDialogView )
            
            UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
                self.addFeedbackDialogView.overlayView.alpha = 0.5
                self.addFeedbackDialogView.contentView.transform = CGAffineTransform( scaleX: 1.0, y: 1.0 )
            }, completion: { (value: Bool) in
                /// Load the correct button sizes and shapes
            })
        }
    }
    
    /// Routes from popups to the bookmarks screen.
    func didTapVisitBookmarks() {
        self.performSegue(withIdentifier: "segueFromWebToBookmarks", sender: nil)
    }
    
    /// Routes from popups to the settings screen.
    func didTapVisitSettings() {
        self.performSegue(withIdentifier: "segueFromWebToSettings", sender: nil)
    }
    
    /// Removes bookmark metadata and shows a temporary confirmation.
    func didTapDeleteBookmark(for url: String?) {
        let bookmarkText = NSAttributedString(
            string: "Bookmark",
            attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 9.0)
            ]
        )
        
        let deletedBookmarkName = content.favoriteName
        
        RealmHelper.sharedInstance.update(content, properties: [
            "favoriteName": "",
            "favorite": false
        ]) { [weak self] _ in
            guard let self = self else { return }
            self.favoriteIcon.setImage(UIImage(named: "icBookmarksFolder"), for: .normal)
            self.favoriteIcon.setAttributedTitle(bookmarkText, for: .normal)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let sceneDelegate = windowScene.delegate as? SceneDelegate,
                       let window = sceneDelegate.window {
                        
                CustomPopUp.showTemporary(
                    in: window,
                    popupLabelText: "Bookmark \(deletedBookmarkName) deleted!",
                    isBookmark: true,
                    bookmarkName: deletedBookmarkName,
                    duration: 1.5
                )
            }
        }
    }

    /// Auto-expands accordion toggles in HTML content.
    private func expandAllToggles() {
        let expandTogglesJS = """
        (function() {
            const chevrons = document.querySelectorAll('.chevron-up');
            chevrons.forEach(function(chevron) {
                chevron.click();  // simulate user clicking the chevron
            });
        })();
        """
        webView.evaluateJavaScript(expandTogglesJS, completionHandler: nil)
    }
    
    
    
    ///--------------------------------------------------------------------------------------------------
    /// Dismisses the keyboard from the note editor.
    @objc func dismissKeyboard() {
        /// To hide the keyboard when the user clicks search
        self.addNoteDialogView.endEditing(true)
    }
}

// Convenience additions for WebViewViewController.
extension WebViewViewController: UISearchBarDelegate {
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        guard let searchText = searchBar.text, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
//            return
//        }
//        
//        // Use the new method that counts and highlights
//        highlightSearchWithCount(term: searchText)
//        
//        // Hide keyboard
//        searchBar.resignFirstResponder()
//    }
    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.text = ""
//        searchBar.resignFirstResponder()
//        removeHighlights()
//    }
    
    /// Debounces in-page search and animates the search navigation UI.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            /// Cancel any existing timer
            searchTimer?.invalidate()
            
            /// Clear highlights if search text is empty
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                removeHighlights()
                
                UIView.animate(withDuration: 0.2, delay: 0) {
                    self.searchNavStackView.transform = CGAffineTransform(translationX: self.searchNavStackView.frame.width, y: 0)
                    self.searchNavStackView.alpha = 0
                } completion: { _ in
                    self.searchNavStackView.isHidden = true
                    self.searchNavStackView.transform = .identity
                    self.searchNavStackView.alpha = 1
                    
                    /// Animate the parent stack view layout change
                    UIView.animate(withDuration: 0.2, delay: 0) {
                        self.view.layoutIfNeeded() // or self.parentStackView.layoutIfNeeded() if you have a reference
                    }
                }
                
                return
            }

            /// Check if searchNavStackView is already visible - if so, don't animate it in again
            let shouldAnimateIn = searchNavStackView.isHidden
            
            /// Set up a new timer to delay the search (debounce)
            searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                
                let current = self.search.text ?? ""
                self.performRealTimeSearch(term: current)
                
                /// Only animate in if it's currently hidden
                if shouldAnimateIn {
                    /// Prepare for right-to-left animation
                    self.searchNavStackView.transform = CGAffineTransform(translationX: self.searchNavStackView.frame.width, y: 0)
                    self.searchNavStackView.alpha = 0
                    self.searchNavStackView.isHidden = false
                    
                    UIView.animate(withDuration: 0.3) {
                        self.searchNavStackView.transform = .identity
                        self.searchNavStackView.alpha = 1
                        self.view.layoutIfNeeded() // This ensures the parent stack view animates the layout change too
                    }
                }
            }
        }
        
        /// Executes a full search when the user presses Search.
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            guard let current = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !current.isEmpty else { return }
            searchTimer?.invalidate()
            highlightSearchWithCount(term: current)
            searchBar.resignFirstResponder()
        }
        
        /// Clears search state and highlights when canceling.
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
            searchBar.resignFirstResponder()
            searchTimer?.invalidate()
            removeHighlights()
        }
        
        /// Method for real-time search with lighter operations
    /// Lightweight search used during typing to keep UI responsive.
    private func performRealTimeSearch(term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            removeHighlights()
            searchNavStackView.isHidden = true
            totalSearchResults = 0
            currentSearchResultIndex = 0
            updateSearchResultsDisplay()
            return
        }
        if let path = Bundle.main.url(forResource: "WebView", withExtension: "js") {
            do {
                let data: Data = try Data(contentsOf: path)
                let jsCode: String = String(decoding: data, as: UTF8.self)
                webView.evaluateJavaScript(jsCode, completionHandler: nil)

                let escaped = trimmed.replacingOccurrences(of: "'", with: "\\'")
                let searchString = "WKWebView_HighlightAllOccurencesOfStringWithNavigation('\(escaped)', true)"
                webView.evaluateJavaScript(searchString) { [weak self] (result, error) in
                    if let count = result as? Int {
                        self?.totalSearchResults = count
                        self?.currentSearchResultIndex = count > 0 ? 1 : 0
                        DispatchQueue.main.async {
                            self?.searchNavStackView.isHidden = count == 0
                            self?.updateSearchResultsDisplay()
                        }
                    }
                }
            } catch {
                print("Could not load javascript: \(error)")
            }
        }
    }
    
    /// Opens the editor for a note selected from the notes sheet.
    func didSelectNote(_ note: Notes) {
        /// This will open the note editing window when a note is selected
        if let selectedNote = realm!.object(ofType: Notes.self, forPrimaryKey: note.id) {
            openNoteWindow(noteChosen: selectedNote)
        }
    }
    
    /// Updates the notes badge count with simple show/hide animation.
    func updateNotesButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let count = self.content?.notes.count ?? 0
            
            if count <= 0 {
                /// Animate fade out and scale down
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                    self.viewNotesButton.alpha = 0
                    self.viewNotesButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }, completion: { _ in
                    self.viewNotesButton.isHidden = true
                    self.viewNotesButton.setTitle("(0)", for: .normal)
                    /// Reset transform for next time it appears
                    self.viewNotesButton.transform = .identity
                })
            } else {
                _ = Int(
                    self.viewNotesButton
                        .title(for: .normal)?
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "") ?? "0"
                ) ?? 0
                
                /// If button is hidden, show it first
                if self.viewNotesButton.isHidden {
                    self.viewNotesButton.isHidden = false
                    self.viewNotesButton.alpha = 0
                    self.viewNotesButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
                
                /// Animate the count change with a pop effect
                UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
                    self.viewNotesButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    self.viewNotesButton.alpha = 1
                }, completion: { _ in
                    self.viewNotesButton.setTitle("(\(count))", for: .normal)
                    
                    UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
                        self.viewNotesButton.transform = .identity
                    })
                })
            }
        }
    }
}
