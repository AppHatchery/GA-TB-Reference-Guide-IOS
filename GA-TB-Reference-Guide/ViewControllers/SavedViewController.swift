//
//  SavedViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/6/21.
//

import UIKit
import RealmSwift

class SavedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var search: UISearchBar!
    
    @IBOutlet weak var contentTabs: UISegmentedControl!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headertitle: UILabel!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyMessage: UILabel!
    @IBOutlet weak var editButton: UIButton!
    var isGradientAdded: Bool = false
    
    // Initialize the Realm database
//    let realm = try! Realm()
    let realm = RealmHelper.sharedInstance.mainRealm()
    var content : ContentPage!
    
    var favoriteURLs = [String]()
    var favoriteNames = [String]()
    var favoriteSubChapters = [String]()
    var favoriteChapters = [String]()
    
    var historyURLs = [String]()
    var historyNames = [String]()
    var historyChapters = [String]()
    
    var notesURLs = [String]()
    var notesTitles = [String]()
    var notesContent = [String]()
    var notesLastEdit = [String]()
    var notesColors = [Int]()
    var colorTags = [UIColor.black, UIColor.systemRed, UIColor.systemOrange, UIColor.systemYellow, UIColor.systemGreen, UIColor.systemTeal, UIColor.systemBlue, UIColor.systemIndigo, UIColor.systemPurple]
    
    var isFavorite : Bool = true
    var isLastOpened : Bool = false
    var isNotes : Bool = false
    
    var arrayPointer : Int = 0
    
    var tableViewCells: [Int : UITableViewCell] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        
        search.delegate = self
//        searchReturns.isHidden = true

        let textFieldInsideSearchBar = search.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.darkGray
        textFieldInsideSearchBar?.layer.cornerRadius = 60
        textFieldInsideSearchBar?.backgroundColor = UIColor.init(white: 255/255, alpha: 1.0)
                
        navigationController?.navigationBar.setGradientBackground(to: self.navigationController!)
        navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register( UITableViewCell.self, forCellReuseIdentifier: type(of: self).description())
        tableView.register(UINib(nibName: "NoteTableViewCell", bundle: nil), forCellReuseIdentifier: "noteCell")
        tableView.estimatedRowHeight = 80
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        customView.backgroundColor = UIColor( red: 0xd5/255.0, green: 0xd8/255.0, blue: 0xdc/255.0, alpha: 1)

        let doneButton = UIButton( frame: CGRect( x: view.frame.width - 70 - 10, y: 0, width: 70, height: 44 ))
        doneButton.setTitle( "Dismiss", for: .normal )
        doneButton.setTitleColor( UIColor.systemBlue, for: .normal)
        doneButton.addTarget( self, action: #selector( self.dismissKeyboard), for: .touchUpInside )
        customView.addSubview( doneButton )
        
        search.inputAccessoryView = customView
        
        toggleState(contentTabs)
    }
    
    //--------------------------------------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
//        if !isGradientAdded {
//            searchView.setGradientBackground(size: searchView.bounds)
//            isGradientAdded = true
//        }
        
        // Refresh the Arrays everytime the view appears, might want to add some sort of observer event to these arrays to not keep loading them everytime on start
        favoriteURLs = [String]()
        favoriteNames = [String]()
        favoriteSubChapters = [String]()
        favoriteChapters = [String]()
        historyURLs = [String]()
        historyNames = [String]()
        historyChapters = [String]()
        notesURLs = [String]()
        notesContent = [String]()
        notesLastEdit = [String]()
        notesColors = [Int]()
        notesTitles = [String]()
                
        let contentDatabase =  realm!.objects(ContentPage.self)
        for content in contentDatabase{
            if content.favorite == true {
                favoriteURLs.append(content.url)
                favoriteNames.append(content.favoriteName)
                favoriteSubChapters.append(content.name)
                favoriteChapters.append(content.chapterParent)
            }
        }
        
        let historyDatabase =  realm!.objects(ContentAccess.self).sorted(byKeyPath: "date",ascending: false)
        for content in historyDatabase{
            historyURLs.append(content.url)
            historyNames.append(content.name)
            historyChapters.append(content.chapterParent)
        }
        
        // Should address the order in which the notes load up because it looks like it follows the last note clicked model rather than appending to the database linearly
        let notesDatabase =  realm!.objects(Notes.self)
        for content in notesDatabase{
            notesURLs.append(content.subChapterURL)
            notesTitles.append(content.subChapterName)
            notesContent.append(content.content)
            notesColors.append(content.colorTag)
            notesLastEdit.append(content.lastEdited)
        }
        
        tableView.reloadData()
        // If number of cells is 0, then
        if tableView.visibleCells.count == 0 {
            emptyView.isHidden = false
            editButton.isHidden = true
        } else {
            emptyView.isHidden = true
            editButton.isHidden = false
        }
    }
        
    //--------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Decide what to display according to the corresponding filter
        if isFavorite {
            return favoriteURLs.count
        } else if isLastOpened {
            return historyURLs.count
        } else if isNotes {
            return notesURLs.count
        } else {
            return 0
        }
    }
    
    private func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isNotes {
            let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath) as! NoteTableViewCell
            cell.backgroundColor = UIColor.backgroundColor
            cell.header.text = "In \(notesTitles[indexPath.row])"
            cell.content.text = notesContent[indexPath.row]
            cell.colorTag.backgroundColor = colorTags[notesColors[indexPath.row]]
            tableViewCells[indexPath.row] = cell
            
            return cell
        } else {
            var cell: UITableViewCell! = tableViewCells[indexPath.row]
            
            cell = UITableViewCell(frame: CGRect( x: 0, y: 0, width: tableView.frame.width, height: tableView.rowHeight ))
            cell.backgroundColor = UIColor.backgroundColor
                
            cell.accessoryType = .disclosureIndicator
            
            if isFavorite {
                cell.textLabel?.text = favoriteNames[indexPath.row]
            } else if isLastOpened {
                cell.textLabel?.text = historyNames[indexPath.row]
            }
            
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.numberOfLines = 6
            tableViewCells[indexPath.row] = cell
            
            return cell
        }
//        tableViewCells[indexPath.row] = cell
//
//
//        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        arrayPointer = indexPath.row
        
        performSegue( withIdentifier: "SegueToWebViewViewController", sender: nil )
    }
    
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete
         {
            
            if isFavorite {
                if let contentDatabase =  realm!.object(ofType: ContentPage.self, forPrimaryKey: favoriteURLs[indexPath.row]){
                    RealmHelper.sharedInstance.update(contentDatabase, properties: [
                        "favorite": false,
                        "favoriteName": ""
                    ]) { updated in
                        //
                        self.favoriteURLs.remove(at: indexPath.row)
                        self.favoriteNames.remove(at: indexPath.row)
                        self.favoriteSubChapters.remove(at: indexPath.row)
                        self.favoriteChapters.remove(at: indexPath.row)
                    }
                }
            } else if isLastOpened {
                let historyDatabase =  realm!.objects(ContentAccess.self).filter("url == '\(historyURLs[indexPath.row])'")
                for entry in historyDatabase {
                    RealmHelper.sharedInstance.delete(entry) { deleted in
                        //
                    }
                }
                historyNames.remove(at: indexPath.row)
                historyURLs.remove(at: indexPath.row)
                historyChapters.remove(at: indexPath.row)
            } else if isNotes {
                let notesDatabase =  realm!.objects(Notes.self)
                RealmHelper.sharedInstance.delete(notesDatabase[indexPath.row]) { deleted in
                    //
                    self.notesContent.remove(at: indexPath.row)
                    self.notesURLs.remove(at: indexPath.row)
                    self.notesLastEdit.remove(at: indexPath.row)
                    self.notesColors.remove(at: indexPath.row)
                }
            }
            
//            try! realm!.write
//            {
//                if isFavorite {
//                    if let contentDatabase = realm!.object(ofType: ContentPage.self, forPrimaryKey: favoriteURLs[indexPath.row]){
//                        contentDatabase.favorite = false
//                        contentDatabase.favoriteName = ""
//                    }
//                    favoriteURLs.remove(at: indexPath.row)
//                    favoriteNames.remove(at: indexPath.row)
//                    favoriteSubChapters.remove(at: indexPath.row)
//                    favoriteChapters.remove(at: indexPath.row)
//                } else if isLastOpened {
//                    let historyDatabase = realm!.objects(ContentAccess.self).filter("url == '\(historyURLs[indexPath.row])'")
//                    realm!.delete(historyDatabase)
//
//                    historyNames.remove(at: indexPath.row)
//                    historyURLs.remove(at: indexPath.row)
//                    historyChapters.remove(at: indexPath.row)
//                } else if isNotes {
//                    let notesDatabase = realm!.objects(Notes.self)
//                    realm!.delete(notesDatabase[indexPath.row])
//
//                    notesContent.remove(at: indexPath.row)
//                    notesURLs.remove(at: indexPath.row)
//                    notesLastEdit.remove(at: indexPath.row)
//                    notesColors.remove(at: indexPath.row)
//                }
//            }
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
         }
    }
    
    //--------------------------------------------------------------------------------------------------
    @IBAction func showEditing(_ sender: UIButton)
     {
        if(self.tableView.isEditing == true)
        {
            self.tableView.setEditing(false, animated: true)
            sender.setTitle("Edit", for: .normal)
        }
        else
        {
            self.tableView.setEditing(true, animated: true)
            sender.setTitle("Done", for: .normal)
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    @IBAction func toggleState(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            headertitle.text = "Your Bookmarks"
            search.placeholder = "Search Bookmarks"
            isLastOpened = false
            isFavorite = true
            isNotes = false
            tableView.separatorStyle = .singleLine
            let attributedString = NSMutableAttributedString(string: "Content you bookmark will appear here.\n\n")
            attributedString.append(NSAttributedString(string: "Tap "))

            
            let loveAttachment = NSTextAttachment()
            loveAttachment.image = UIImage(systemName: "star")?.withTintColor(UIColor.label)
            loveAttachment.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
            attributedString.append(NSAttributedString(attachment: loveAttachment))
            attributedString.append(NSAttributedString(string: " on any chart or subchapter."))

            emptyMessage.attributedText = attributedString
        case 1:
            headertitle.text = "Last Opened"
            search.placeholder = "Search Recents"
            isLastOpened = true
            isFavorite = false
            isNotes = false
            tableView.separatorStyle = .singleLine
            emptyMessage.text = """
            Content you view will appear here.

            Start by opening any subchapter or chart.
            """
        case 2:
            headertitle.text = "Your Notes"
            search.placeholder = "Search Notes"
            isLastOpened = false
            isFavorite = false
            isNotes = true
            tableView.separatorStyle = .none
            let attributedString = NSMutableAttributedString(string: "Notes you create will appear here.\n\n")
            attributedString.append(NSAttributedString(string: "Tap "))

            let loveAttachment = NSTextAttachment()
            loveAttachment.image = UIImage(named: "icEditNote")
            loveAttachment.bounds = CGRect(x: 0, y: -3, width: 20, height: 20)
            attributedString.append(NSAttributedString(attachment: loveAttachment))
            attributedString.append(NSAttributedString(string: " on any chart or subchapter."))

            emptyMessage.attributedText = attributedString
        default:
            print("nothing selected")
        }
        
        tableView.reloadData()
        if tableView.visibleCells.count == 0 {
            emptyView.isHidden = false
            editButton.isHidden = true
        } else {
            emptyView.isHidden = true
            editButton.isHidden = false
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let webViewViewController = segue.destination as? WebViewViewController
        {
            if isFavorite {
                webViewViewController.url = Bundle.main.url(forResource: favoriteURLs[arrayPointer], withExtension: "html")!
                webViewViewController.titlelabel = favoriteSubChapters[arrayPointer]
                webViewViewController.navTitle = favoriteChapters[arrayPointer]
                webViewViewController.uniqueAddress = favoriteURLs[arrayPointer]
            } else if isLastOpened {
                webViewViewController.url = Bundle.main.url(forResource: historyURLs[arrayPointer], withExtension: "html")!
                webViewViewController.titlelabel = historyNames[arrayPointer]
                webViewViewController.navTitle = historyChapters[arrayPointer]
                webViewViewController.uniqueAddress = historyURLs[arrayPointer]
            } else if isNotes {
                // Add the transition to the correct viewontroller
                webViewViewController.url = Bundle.main.url(forResource: notesURLs[arrayPointer], withExtension: "html")!
                webViewViewController.titlelabel = notesTitles[arrayPointer]
//                webViewViewController.navTitle = historyChapters[arrayPointer]
                webViewViewController.uniqueAddress = notesURLs[arrayPointer]
            }
        }
    }
    
    //--------------------------------------------------------------------------------------------------
    // To hide the keyboard when the user clicks search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    
    //--------------------------------------------------------------------------------------------------
    @objc func dismissKeyboard() {
        // To hide the keyboard when the user clicks search
        self.view.endEditing(true)
    }
    
}
