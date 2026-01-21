//
//  DeleteConfirmationPopUp.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 08/10/2025.
//

import UIKit

protocol DeleteConfirmationPopUpDelegate: AnyObject {
    func didTapDeleteBookmark(for url: String?)
}

class DeleteConfirmationPopUp: UIView {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet var buttons: [UIButton]!

    var contentViewTopConstraint: NSLayoutConstraint!
    
    weak var delegate: DeleteConfirmationPopUpDelegate?
    var bookmarkName: String = ""
    var bookmarkUrl: String?
    
    //------------------------------------------------------------------------------
    init(frame: CGRect, bookmarkName: String, bookmarkUrl: String? = nil, delegate: DeleteConfirmationPopUpDelegate? = nil) {
        super.init(frame: frame)
        
        self.bookmarkName = bookmarkName
        self.bookmarkUrl = bookmarkUrl
        self.delegate = delegate
        
        customInit()
    }
    
    //------------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        customInit()
    }
    
    //------------------------------------------------------------------------------
    func customInit() {
        let nibView = (Bundle.main.loadNibNamed("DeleteConfirmationPopUp", owner: self, options: nil)!.first as! UIView)
        self.addSubview(nibView)
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        nibView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentViewTopConstraint = nibView.topAnchor.constraint(equalTo: self.topAnchor)
        
        contentViewTopConstraint.isActive = true
        
        mainView.layer.cornerRadius = 4
        mainView.layer.masksToBounds = true
        
        contentLabel.text = bookmarkName
        
        configureCancelButton()
        configureDeleteButton()
        
        cancelButton
            .addTarget(
                self,
                action: #selector(cancelButtonPressed),
                for: .touchUpInside
            )
        deleteButton
            .addTarget(
                self,
                action: #selector(deleteButtonPressed),
                for: .touchUpInside
            )
    }
    
    private func configureCancelButton() {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = "Cancel"
            config.cornerStyle = .fixed
            config.baseForegroundColor = .label
            config.background.cornerRadius = 0

            cancelButton.configuration = config
            cancelButton.configurationUpdateHandler = { button in
                var updatedConfig = button.configuration
                switch button.state {
                case .highlighted:
                    updatedConfig?.background.backgroundColor = .systemGray5
                default:
                    updatedConfig?.background.backgroundColor = .clear
                }
                button.configuration = updatedConfig
            }
        } else {
            cancelButton.layer.borderWidth = 0
            cancelButton.layer.cornerRadius = 0
            cancelButton.layer.masksToBounds = true
        }
    }

    private func configureDeleteButton() {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()

            config.title = "Yes"
            config.cornerStyle = .fixed
            config.baseBackgroundColor = .colorPrimary
            config.baseForegroundColor = .white
            config.background.cornerRadius = 0

            deleteButton.configuration = config
        } else {
            deleteButton.layer.borderWidth = 0
            deleteButton.layer.cornerRadius = 0
            deleteButton.layer.masksToBounds = true
        }
    }
    
    //------------------------------------------------------------------------------
    @objc func cancelButtonPressed() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backgroundView.alpha = 0
            self.mainView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    @objc func deleteButtonPressed() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backgroundView.alpha = 0
            self.mainView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.delegate?.didTapDeleteBookmark(for: self.bookmarkUrl)
            self.removeFromSuperview()
        })
    }
    
    //------------------------------------------------------------------------------
    // Convenience method to show the popup
    static func show(in window: UIWindow, bookmarkName: String, bookmarkUrl: String? = nil, delegate: DeleteConfirmationPopUpDelegate? = nil) {
        let popup = DeleteConfirmationPopUp(
            frame: window.bounds,
            bookmarkName: bookmarkName,
            bookmarkUrl: bookmarkUrl,
            delegate: delegate
        )
        popup.mainView.transform = CGAffineTransform(scaleX: 0, y: 0)
        popup.backgroundView.alpha = 0
        
        window.addSubview(popup)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            popup.backgroundView.alpha = 0.5
            popup.mainView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
}
