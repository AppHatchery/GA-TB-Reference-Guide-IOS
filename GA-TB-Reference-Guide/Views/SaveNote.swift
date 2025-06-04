//
//  SaveNote.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/11/21.
//

import UIKit
import RealmSwift

protocol SaveNoteDelegate
{
    func didSaveNote( _ note: Notes )
    
    func didDeleteNote( _ note: Notes)
}

class SaveNote: UIView {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var noteField: UITextView!
    @IBOutlet weak var tagLabel: UILabel!
    
    // Dialog Constraints
    @IBOutlet weak var dialogLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var dialogRightConstraint: NSLayoutConstraint!
    
    @IBOutlet var colors: [UIButton]!
    
    var contentViewTopConstraint: NSLayoutConstraint!
    var delegate: SaveNoteDelegate!
    var subChapter: ContentPage!
    var note: Notes!
    var highlightedColor: UIView!
    var colorTags = [UIColor]()
    var colorTagChosen = 0
    let realm = RealmHelper.sharedInstance.mainRealm()

    //------------------------------------------------------------------------------
    init( frame: CGRect, content: ContentPage, oldNote: Notes, delegate: SaveNoteDelegate )
    {
        super.init( frame : frame )
    
        self.delegate = delegate
        self.subChapter = content
        self.note = oldNote

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
        let nibView = (Bundle.main.loadNibNamed( "SaveNote", owner: self, options: nil)!.first as! UIView)
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
        
        noteField.layer.cornerRadius = 4
        noteField.layer.masksToBounds = true
                
        cancelButton.layer.borderWidth = 0
        cancelButton.layer.cornerRadius = 0
        cancelButton.layer.masksToBounds = true

        saveButton.layer.borderWidth = 0
        saveButton.layer.cornerRadius = 0
        saveButton.layer.masksToBounds = true
        
        closeButton.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        
        cancelButton.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        
        for button in colors {
            button.addTarget(self, action: #selector(self.pickColor), for: .touchDown)
        }
        highlightedColor = UIView(frame: colors[0].bounds)
        
        if note.savedToRealm == true {
            titleLabel.text = "Edit Note"
            noteField.text = note.content
            colors[note.colorTag].addSubview(highlightedColor)
            highlightedColor.isUserInteractionEnabled = false
            colorTagChosen = note.colorTag
            cancelButton.setTitle("Delete", for: .normal)
            saveButton.setTitle("Update", for: .normal)
            cancelButton.addTarget(self, action: #selector(self.deleteButtonPressed), for: .touchUpInside)
            cancelButton.setImage(UIImage(systemName: "trash"), for: .normal)
        }
    }
    
    //------------------------------------------------------------------------------
    @objc func pickColor(_ sender: UIButton){
        // Remove the current highlighted button by removing all
        // NOT VERY EFFICIENT, SHOULD OPTIMIZE THIS BY KNOWING BEFOREHAND WHICH ONE IS TURNED ON
        for button in colors {
            button.willRemoveSubview(highlightedColor)
        }

        sender.addSubview(highlightedColor)
        
        // Assign color to tag
//        note.colorTag = sender.tag
        colorTagChosen = sender.tag
    }
    
    //------------------------------------------------------------------------------
    @IBAction func saveButtonPressed(_ sender: Any )
    {
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            // Realm
            RealmHelper.sharedInstance.update(self.note, properties: [
                "content":self.noteField.text!,
                "colorTag":self.colorTagChosen
            ]) { updated in
                //
            }
//            try! self.realm!.write
//            {
//                self.note.content = self.noteField.text
//                self.note.colorTag = self.colorTagChosen
//            }
            self.delegate.didSaveNote(self.note)
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
    @objc func deleteButtonPressed(_ sender: Any)
    {
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            
            self.delegate.didDeleteNote(self.note)
            self.removeFromSuperview()
        })
    }
}
