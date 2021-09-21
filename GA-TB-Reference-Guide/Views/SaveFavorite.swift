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

        contentViewTopConstraint.isActive = true
        
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
                
        cancelButton.layer.borderWidth = 0.5
        cancelButton.layer.cornerRadius = 4
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.borderColor = UIColor.black.cgColor

        saveButton.layer.borderWidth = 0.5
        saveButton.layer.cornerRadius = 4
        saveButton.layer.masksToBounds = true
        saveButton.layer.borderColor = UIColor.black.cgColor
        
        if subChapter.favorite == true {
            titleLabel.text = "Edit Bookmark Title"
            nameField.text = subChapter.favoriteName
            cancelButton.setTitle("Remove", for: .normal)
            saveButton.setTitle("Update", for: .normal)
            cancelButton.addTarget(self, action: #selector(self.deleteButtonPressed), for: .touchUpInside)
            cancelButton.setImage(UIImage(systemName: "trash"), for: .normal)
        } else {
            nameField.text = currentTitle
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
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            
            self.delegate.didRemoveFavorite()
            self.removeFromSuperview()
        })
    }
    
}
