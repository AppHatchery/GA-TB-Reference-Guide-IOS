//
//  SubChapterListView.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit

protocol SubChapterListViewDelegate
{
    
}

class SubChapterListView: UIView, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    static let kHeight = 632
    var tableViewCells: [Int : UITableViewCell] = [:]
    var contentView: UIView!
    var contentViewTopConstraint: NSLayoutConstraint!
    var delegate: SubChapterListViewDelegate!
    
    var chapters = ["I. Epidemiology","II. Diagnostic Tests for Latent TB Infection (LTBI)","III. Treatment of Latent TB Infection (LTBI)","IV. Laboratory Diagnosis of Active Tuberculosis","V. Treatment of Current (Active) Disease Therapy","VI. Pregnancy and TB","VII. Childhood Tuberculosis","VIII. Tuberculosis and Long-Term Care Facilities","IX. BCG Vaccination","X. TB Infection Control: Hospital Isolation Procedures","XI. Community Tuberculosis Control","XII. Alternative Housing Program for Homeless TB Patients in Georgia","XIII. Georgia Department of Public Health (DPH) Community Guidelines for Respiratory Isolation of Patients with Active TB in the Community","XIV. References","XV. Appendix: District TB Coordinators (by District)"]
    
    //------------------------------------------------------------------------------
    init( frame: CGRect, delegate: SubChapterListViewDelegate )
    {
        super.init( frame : frame )
    
        self.delegate = delegate

        customInit()
    }
    
    //------------------------------------------------------------------------------
    required init?( coder aDecoder: NSCoder )
    {
        super.init( coder : aDecoder )
        
        customInit()
    }
    
    //------------------------------------------------------------------------------
    func customInit()
    {
        contentView = (Bundle.main.loadNibNamed( "SubChapterListView", owner: self, options: nil)!.first as! UIView)
        self.addSubview( contentView )
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.leftAnchor.constraint( equalTo: self.leftAnchor ).isActive = true
        contentView.rightAnchor.constraint( equalTo: self.rightAnchor ).isActive = true
        contentView.bottomAnchor.constraint( equalTo: self.bottomAnchor ).isActive = true
        contentViewTopConstraint = contentView.topAnchor.constraint( equalTo: self.topAnchor )

        contentViewTopConstraint.isActive = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register( UITableViewCell.self, forCellReuseIdentifier: type(of: self).description())
        tableView.estimatedRowHeight = 80
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }
    //------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
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
            
            cell.accessoryType = .disclosureIndicator
            
            cell.textLabel?.text = chapters[indexPath.row]
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.numberOfLines = 6
            
            tableViewCells[indexPath.row] = cell
            
        }
                
        return cell
    }
}
