//
//  SettingsViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 11/16/21.
//

import UIKit

class SettingsViewController: UIViewController {

    var scrollView: UIScrollView!
    var settingsView: Settings!
    
    @IBOutlet weak var contentView: UIView!
    
    var url: URL!
    var header: String!
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
                
        navigationController?.navigationBar.setGradientBackground(to: self.navigationController!)
        navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        if scrollView == nil {
            
            scrollView = UIScrollView( frame: view.frame )
            scrollView.backgroundColor = UIColor.clear
            contentView.addSubview( scrollView )
            scrollView.delaysContentTouches = false
                    
            settingsView = Settings(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height))
            scrollView.addSubview(settingsView)
                    
            scrollView.contentSize = CGSize(width: contentView.frame.width, height: 700)
        }
    }
    
    @IBAction func tapContactUs(_ sender: UIButton){
        let email = "morgan.greenleaf@emory.edu"
        if let url = URL(string: "mailto:\(email)") {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
          } else {
            UIApplication.shared.openURL(url)
          }
        }
    }
    
    @IBAction func tapPrivacyPolicy(_ sender: UIButton){
        url = Bundle.main.url(forResource: "georgia-tb-privacy-policy", withExtension: "html")!
        performSegue(withIdentifier: "SegueToSettingsView", sender: nil)
    }
    
    @IBAction func tapAbout(_ sender: UIButton){
        url = Bundle.main.url(forResource: "1_epidemiology", withExtension: "html")!
        performSegue(withIdentifier: "SegueToSettingsView", sender: nil)
    }
    
    @IBAction func tapReset(_ sender: UIButton){
        let alertDelete = UIAlertController(title: "Attention", message: "This will permanently reset the app to factory settings. Are you sure you want to proceed?", preferredStyle: .alert)
        alertDelete.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
        }))
        alertDelete.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
        }))
        self.present(alertDelete, animated: true, completion: nil)
    }
    
    //--------------------------------------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let settingsViewController = segue.destination as? SettingsViewsViewController
        {
            settingsViewController.url = url
        }
    }
}
