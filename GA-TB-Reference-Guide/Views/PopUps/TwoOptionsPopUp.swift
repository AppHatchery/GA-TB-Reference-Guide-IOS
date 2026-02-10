//
//  TwoOptionsPopUp.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 10/02/2026.
//

import UIKit

class TwoOptionsPopUp: UIView {
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet var buttons: [UIButton]!
    
    var customLabel: String = ""
    
    var cancelAction: (() -> Void)?
    var deleteAction: (() -> Void)?

    //------------------------------------------------------------------------------
    init(frame: CGRect, customLabel: String, cancelAction: (() -> Void)? = nil, deleteAction: (() -> Void)? = nil) {
        self.customLabel = customLabel
        self.cancelAction = cancelAction
        self.deleteAction = deleteAction
        super.init(frame: frame)
        
        customInit(label: customLabel)
    }
    
    //------------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder) {
        self.customLabel = ""
        self.cancelAction = nil
        self.deleteAction = nil
        super.init(coder: aDecoder)
        
        customInit(label: self.customLabel)
    }
    
    //------------------------------------------------------------------------------
    func customInit(label: String) {
        let nibView = (Bundle.main.loadNibNamed("TwoOptionsPopUp", owner: self, options: nil)!.first as! UIView)
        self.addSubview(nibView)
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        
        nibView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        nibView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        nibView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        mainView.layer.cornerRadius = 4
        mainView.layer.masksToBounds = true
        
        contentLabel.text = label
        
        configureCancelButton()
        configureDeleteButton()

        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelButtonPressed))
        backgroundView.addGestureRecognizer(tap)
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

    @objc private func cancelButtonPressed() {
        dismiss { [weak self] in
            self?.cancelAction?()
        }
    }

    @objc private func deleteButtonPressed() {
        dismiss { [weak self] in
            self?.deleteAction?()
        }
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backgroundView.alpha = 0
            self.mainView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    static func show(in window: UIWindow, label: String, cancelTitle: String = "Cancel", deleteTitle: String = "Yes", onCancel: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        let popup = TwoOptionsPopUp(frame: window.bounds, customLabel: label, cancelAction: onCancel, deleteAction: onDelete)
        if #available(iOS 15.0, *) {
            popup.cancelButton.configuration?.title = cancelTitle
            popup.deleteButton.configuration?.title = deleteTitle
        } else {
            popup.cancelButton.setTitle(cancelTitle, for: .normal)
            popup.deleteButton.setTitle(deleteTitle, for: .normal)
        }
        window.addSubview(popup)
        popup.mainView.transform = CGAffineTransform(scaleX: 0, y: 0)
        popup.backgroundView.alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            popup.backgroundView.alpha = 0.5
            popup.mainView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
}
