//
//  SaveNote.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/11/21.
//

import UIKit

protocol SaveNoteDelegate
{
    func didSaveNote( _ note: Notes )
    
    func didDeleteNote()
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
    
    @IBOutlet var colors: [UIButton]!
    
    var contentViewTopConstraint: NSLayoutConstraint!
    var delegate: SaveNoteDelegate!
    var subChapter: ContentPage!
    var note: Notes!
    let highlightedColor = UIView(frame: CGRect(x: -3, y: -3, width: 26, height: 26))
    var colorTags = [UIColor]()

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

        contentViewTopConstraint.isActive = true
        
        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true
        
        noteField.layer.cornerRadius = 4
        noteField.layer.masksToBounds = true
                
        cancelButton.layer.borderWidth = 0.5
        cancelButton.layer.cornerRadius = 4
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.borderColor = UIColor.black.cgColor

        saveButton.layer.borderWidth = 0.5
        saveButton.layer.cornerRadius = 4
        saveButton.layer.masksToBounds = true
        saveButton.layer.borderColor = UIColor.black.cgColor
        
        closeButton.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        
        cancelButton.addTarget(self, action: #selector(self.cancelButtonPressed), for: .touchUpInside)
        
        for button in colors {
            button.addTarget(self, action: #selector(self.pickColor), for: .touchDown)
        }
        
        highlightedColor.backgroundColor = UIColor.clear
        highlightedColor.layer.borderWidth = 1.5
        highlightedColor.layer.borderColor = UIColor.systemBlue.cgColor
        highlightedColor.layer.cornerRadius = 13
        // Defaulting to black color selected
        colors[0].addSubview(highlightedColor)
        
        if note.savedToRealm == true {
            titleLabel.text = "Edit Note"
            noteField.text = note.content
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
        note.colorTag = sender.tag
    }
    
    //------------------------------------------------------------------------------
    @IBAction func saveButtonPressed(_ sender: Any )
    {
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            self.note.content = self.noteField.text
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
    @objc func deleteButtonPressed()
    {
        UIView.animate( withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            self.overlayView.alpha = 0
            self.contentView.transform = CGAffineTransform( scaleX: 0.001, y: 0.001 )
        }, completion: { (value: Bool) in
            
            self.delegate.didDeleteNote()
            self.removeFromSuperview()
        })
    }
}
