//
//  CustomPopUp.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 08/10/2025.
//

import UIKit

class CustomPopUp: UIView {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var popupLabel: UILabel!

    var contentViewTopConstraint: NSLayoutConstraint!
    var popupLabelText: String = ""
    
    var isBookmark: Bool = false
    var bookmarkName: String = ""
    
    
    init(frame: CGRect, popupLabelText: String, isBookmark: Bool = false, bookmarkName: String = "") {
        super.init(frame: frame)
        
        self.popupLabelText = popupLabelText
        self.isBookmark = isBookmark
        self.bookmarkName = bookmarkName
        
        customInit()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        customInit()
    }
    
    
    func customInit() {
        let nibView = (Bundle.main.loadNibNamed("CustomPopUp", owner: self, options: nil)!.first as! UIView)
        self.addSubview(nibView)
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        nibView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentViewTopConstraint = nibView.topAnchor.constraint(equalTo: self.topAnchor)
        
        contentViewTopConstraint.isActive = true
        
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.alpha = 0
        
        mainView.layer.cornerRadius = 4
        mainView.layer.masksToBounds = true
        
        if !isBookmark {
            popupLabel.text = "Note Deleted"
        } else {
            if bookmarkName.isEmpty {
                popupLabel.text = "Bookmark deleted!"
            } else {
                popupLabel
                    .setText(
                        "Bookmark \(bookmarkName) deleted!",
                        highlightedStrings: ["\(bookmarkName)"]
                    )
            }
        }
    }
    
    static func showTemporary(in window: UIWindow, popupLabelText: String, isBookmark: Bool = false, bookmarkName: String? = nil, duration: TimeInterval = 1.5) {
            let popup = CustomPopUp(
                frame: window.bounds,
                popupLabelText: popupLabelText,
                isBookmark: isBookmark,
                bookmarkName: bookmarkName ?? ""
            )
            
            popup.mainView.transform = CGAffineTransform(scaleX: 0, y: 0)
            popup.backgroundView.alpha = 0
            
            window.addSubview(popup)
            
            // Animate popup appearance
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
                popup.backgroundView.alpha = 0.5
                popup.mainView.transform = CGAffineTransform.identity
            }) { _ in
                // After delay, dismiss popup
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
                        popup.backgroundView.alpha = 0
                        popup.mainView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    }) { _ in
                        popup.removeFromSuperview()
                    }
                }
            }
        }
}
