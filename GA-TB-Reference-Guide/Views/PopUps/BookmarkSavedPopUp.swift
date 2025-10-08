//
//  BookmarkSavedPopUp.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 08/10/2025.
//

import UIKit

protocol BookmarkSavedPopUpDelegate {
    func didTapVisitBookmarks()
}

class BookmarkSavedPopUp: UIView {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var visitButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    
    @IBOutlet var buttons: [UIButton]!
        
    var contentViewTopConstraint: NSLayoutConstraint!
    var delegate: BookmarkSavedPopUpDelegate?
    var bookmarkName: String = ""
    
    
    init(frame: CGRect, bookmarkName: String, delegate: BookmarkSavedPopUpDelegate? = nil) {
        super.init(frame: frame)
        
        self.bookmarkName = bookmarkName
        self.delegate = delegate
        
        customInit()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        customInit()
    }
    
    
    func customInit() {
        let nibView = (Bundle.main.loadNibNamed("BookmarkSavedPopUp", owner: self, options: nil)!.first as! UIView)
        self.addSubview(nibView)
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        nibView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentViewTopConstraint = nibView.topAnchor.constraint(equalTo: self.topAnchor)
        
        contentViewTopConstraint.isActive = true
        
        mainView.layer.cornerRadius = 4
        mainView.layer.masksToBounds = true
        
        contentLabel.setText(
            "Bookmarked! Now you can quickly access this content through My Bookmarks on Home page",
            highlightedStrings: ["My Bookmarks", "Home"]
        )

        
        for button in buttons {
            button.layer.cornerRadius = 0
            button.layer.masksToBounds = true
            button.layer.borderWidth = 0
        }
        
        visitButton.addTarget(self, action: #selector(visitButtonPressed), for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(dismissButtonPressed), for: .touchUpInside)
    }
    
    
    @objc func visitButtonPressed() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backgroundView.alpha = 0
            self.mainView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.delegate?.didTapVisitBookmarks()
            self.removeFromSuperview()
        })
    }
    
    
    @objc func dismissButtonPressed() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backgroundView.alpha = 0
            self.mainView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }
    
    
    // Convenience method to show the popup
    static func show(in window: UIWindow, bookmarkName: String, delegate: BookmarkSavedPopUpDelegate? = nil) {
        let popup = BookmarkSavedPopUp(frame: window.bounds, bookmarkName: bookmarkName, delegate: delegate)
        popup.mainView.transform = CGAffineTransform(scaleX: 0, y: 0)
        popup.backgroundView.alpha = 0
        
        window.addSubview(popup)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            popup.backgroundView.alpha = 0.5
            popup.mainView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
}
