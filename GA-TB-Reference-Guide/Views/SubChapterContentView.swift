//
//  SubChapterContentView.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.
//

import UIKit
import WebKit

protocol SubChapterContentViewDelegate
{
    
}

class SubChapterContentView: UIView {

    @IBOutlet weak var webView: WKWebView!
    
    static let kHeight = 632
    var contentView: UIView!
    var contentViewTopConstraint: NSLayoutConstraint!
    var delegate: SubChapterContentViewDelegate!
    var url: URL!
    
    
    //------------------------------------------------------------------------------
    init( frame: CGRect, delegate: SubChapterContentViewDelegate )
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
        contentView = (Bundle.main.loadNibNamed( "SubChapterContentView", owner: self, options: nil)!.first as! UIView)
        self.addSubview( contentView )
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.leftAnchor.constraint( equalTo: self.leftAnchor ).isActive = true
        contentView.rightAnchor.constraint( equalTo: self.rightAnchor ).isActive = true
        contentView.bottomAnchor.constraint( equalTo: self.bottomAnchor ).isActive = true
        contentViewTopConstraint = contentView.topAnchor.constraint( equalTo: self.topAnchor )

        contentViewTopConstraint.isActive = true
        
//        let url = URL(string: "6_pregnancy_and_tb__a__treatment_for_ltbi_and_risk_factors.html")!
        
//        webView.load( URLRequest( url: url ))
        
    }

}
