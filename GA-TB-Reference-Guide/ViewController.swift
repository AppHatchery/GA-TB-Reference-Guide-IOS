//
//  ViewController.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {
    
    let chapterIndex = ChapterIndex()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Load up the Database with all subchapter content
//        let realm = try! Realm()
//
//        let contentPages = realm.objects( ContentPage.self )
//                
//        for content in contentPages
//        {
//            try! realm.write
//            {
//                realm.add( content )
//            }
//            print(content)
//        }
        
    }


}

