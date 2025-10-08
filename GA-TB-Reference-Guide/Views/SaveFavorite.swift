//
//  SaveFavorite.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/10/21.
//

import UIKit

protocol SaveFavoriteDelegate
{
    func didSaveName( _ name: String )
    
    func didRemoveFavorite()
}

class SaveFavorite: UIView {
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var bookmarkSourceField: UITextField!
    
    // Dialog Constraints
    @IBOutlet weak var dialogLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var dialogRightConstraint: NSLayoutConstraint!
    
    var contentViewTopConstraint: NSLayoutConstraint!
    var delegate: SaveFavoriteDelegate!
    var subChapter: ContentPage!
    var currentTitle: String!

    //------------------------------------------------------------------------------
    init( frame: CGRect, content: ContentPage, title: String, delegate: SaveFavoriteDelegate )
    {
        super.init( frame : frame )
    
        self.delegate = delegate
        self.subChapter = content
        self.currentTitle = title

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
        let nibView = (Bundle.main.loadNibNamed( "SaveFavorite", owner: self, options: nil)!.first as! UIView)
        self.addSubview( nibView )
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint( equalTo: self.leftAnchor ).isActive = true
        nibView.rightAnchor.constraint( equalTo: self.rightAnchor ).isActive = true
        nibView.bottomAnchor.constraint( equalTo: self.bottomAnchor ).isActive = true
        contentViewTopConstraint = nibView.topAnchor.constraint( equalTo: self.topAnchor )
        
        if self.frame.width > 1000 {
            dialogLeftConstraint.constant = 240
            dialogRightConstraint.constant = 240
        }

        contentViewTopConstraint.isActive = true
        
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
                
        cancelButton.layer.borderWidth = 0
        cancelButton.layer.cornerRadius = 0
		cancelButton.layer.masksToBounds = true
        cancelButton.layer.borderColor = UIColor.label.cgColor

        saveButton.layer.borderWidth = 0
        saveButton.layer.cornerRadius = 0
        saveButton.layer.masksToBounds = true
        saveButton.layer.borderColor = UIColor.label.cgColor
        
        
        let nameFieldPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: nameField.frame.height))
        
        nameField.layer.cornerRadius = 10
        nameField.layer.borderWidth = 0
        nameField.layer.borderColor = UIColor.clear.cgColor
        nameField.layer.masksToBounds = true
        nameField.borderStyle = .none
        nameField.leftView = nameFieldPaddingView
        nameField.leftViewMode = .always
        
        let bookmarkSourceFieldPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: bookmarkSourceField.frame.height))
        
        bookmarkSourceField.layer.cornerRadius = 10
        bookmarkSourceField.layer.borderWidth = 0
        bookmarkSourceField.layer.borderColor = UIColor.clear.cgColor
        bookmarkSourceField.layer.masksToBounds = true
        bookmarkSourceField.borderStyle = .none
        bookmarkSourceField.leftView = bookmarkSourceFieldPaddingView
        bookmarkSourceField.leftViewMode = .always
        
        if subChapter.favorite == true {
            titleLabel.text = "Edit Bookmark Title"
            nameField.text = subChapter.favoriteName
            bookmarkSourceField.text = subChapter.name
            
            cancelButton.setTitle("Delete Bookmark", for: .normal)
            saveButton.setTitle("Save Changes", for: .normal)
            cancelButton.addTarget(self, action: #selector(self.deleteButtonPressed), for: .touchUpInside)
        } else {
            nameField.text = currentTitle
            bookmarkSourceField.text = subChapter.chapterParent
            cancelButton.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        }
        closeButton.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
    }
    
    //------------------------------------------------------------------------------
    @IBAction func saveButtonPressed(_ sender: Any )
    {
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            
            self.delegate.didSaveName(self.nameField.text ?? "NA")
            self.removeFromSuperview()
        })
    }
    
    //------------------------------------------------------------------------------
    @objc func cancelButtonPressed()
    {
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            self.removeFromSuperview()
        })
    }
    
    //------------------------------------------------------------------------------
    @objc func deleteButtonPressed()
    {
        UIView.animate(
 withDuration: 0.25,
 delay: 0.0,
 options: UIView.AnimationOptions(),
 animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        },
 completion: { (value: Bool) in
            self.delegate.didRemoveFavorite()
            self.removeFromSuperview()
        })
    }
}
