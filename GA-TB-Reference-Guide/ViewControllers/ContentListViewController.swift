//
//  ContentListViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit

class ContentListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    var tableViewCells: [Int : UITableViewCell] = [:]
    var url: URL!
    var subChapterURL: URL!
    
    var arrayPointer = 0
        
    var chapters = ["Hello and Welcome Clinical Statement","I. Epidemiology","II. Diagnostic Tests for Latent TB Infection (LTBI)","III. Treatment of Latent TB Infection (LTBI)","IV. Laboratory Diagnosis of Active Tuberculosis","V. Treatment of Current (Active) Disease Therapy","VI. Pregnancy and TB","VII. Childhood Tuberculosis","VIII. Tuberculosis and Long-Term Care Facilities","IX. BCG Vaccination","X. TB Infection Control: Hospital Isolation Procedures","XI. Community Tuberculosis Control","XII. Alternative Housing Program for Homeless TB Patients in Georgia","XIII. Georgia Department of Public Health (DPH) Community Guidelines for Respiratory Isolation of Patients with Active TB in the Community","XIV. References","XV. Appendix: District TB Coordinators (by District)","XVI. Abbreviations","XVII. Acknowledgements","XVIII. For more information"]
        
    let chapterIndex = ChapterIndex()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
        let navbarTitle = UILabel()
        navbarTitle.text = "All Chapters"
        navbarTitle.textColor = UIColor.white
        navbarTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
        navbarTitle.numberOfLines = 3
        navbarTitle.textAlignment = .center
        navbarTitle.minimumScaleFactor = 0.7
        navbarTitle.adjustsFontSizeToFitWidth = true
        navigationItem.titleView = navbarTitle
        navigationItem.backButtonDisplayMode = .minimal
        
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
        return chapters.count
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
            
            cell.textLabel?.text = chapters[indexPath.row]
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
        arrayPointer = indexPath.row
        
        performSegue( withIdentifier: "SegueToSubChapterViewController", sender: nil )
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let subChapterViewController = segue.destination as? SubChapterViewController
        {
            subChapterViewController.arrayPointer = arrayPointer
            subChapterViewController.navTitle = chapters[arrayPointer]
        }
    }
}
