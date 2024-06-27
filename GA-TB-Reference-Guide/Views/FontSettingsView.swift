//
//  FontSettingsView.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 27/06/2024.
//

import UIKit
import WebKit

class FontSettingsView: UIViewController {
    var webView: WKWebView!
    var webViewTopConstraint: NSLayoutConstraint!
    var bottomAnchor: CGFloat = 0
    
    var fontSizeLabel: String = "Regular"
    var fontNumber: Int = 100
    let realm = RealmHelper.sharedInstance.mainRealm()
    var userSettings : UserSettings!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var fontSlider: UISlider!
    @IBOutlet weak var fontSize: UILabel!
    @IBOutlet var fontSizeElementCollection: [UIView]!
    @IBAction func closePopUpButton(_ sender: UIImageView) {
        hide()
    }
    
    @IBAction func fontSizeChanger(_ sender: UISlider){
        if fontSizeLabel == "Small" {
            if sender.value > 0.85 && sender.value < 1.15 {
                sliderControl(state: 100)
            } else if sender.value >= 1.15 && sender.value <= 1.5 {
                sliderControl(state: 150)
            } else if sender.value > 1.5 {
                sliderControl(state: 175)
            } else {
                sliderControl(state: 75)
            }
        } else if fontSizeLabel == "Regular"{
            if sender.value < 1.0 {
                sliderControl(state: 75)
            } else if sender.value > 1.2 && sender.value <= 1.5 {
                sliderControl(state: 150)
            } else if sender.value > 1.5 {
                sliderControl(state: 175)
            } else {
                sliderControl(state: 100)
            }
        } else if fontSizeLabel == "Large"{
            if sender.value > 0.95 && sender.value < 1.3 {
                sliderControl(state: 100)
            } else if sender.value <= 0.95 {
                sliderControl(state: 75)
            } else if sender.value > 1.5 {
                sliderControl(state: 175)
            } else {
                sliderControl(state: 150)
            }
        } else if fontSizeLabel == "ExtraLarge"{
            if sender.value > 0.95 && sender.value < 1.25 {
                sliderControl(state: 100)
            } else if sender.value <= 0.95 {
                sliderControl(state: 75)
            } else if sender.value < 1.65  && sender.value >= 1.25 {
                sliderControl(state: 150)
            } else {
                sliderControl(state: 175)
            }
        }
        
        RealmHelper.sharedInstance.update(userSettings, properties: [
            "fontSize":fontNumber
        ]) { updated in
            //
        }
        
//        try! realm!.write {
//            userSettings.fontSize = fontNumber
//        }
        webView.reload()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configView()
        if let currentSettings = realm!.object(ofType: UserSettings.self, forPrimaryKey: "savedSettings"){
            // Assign the older entry to the current variable
            userSettings = currentSettings
            sliderControl(state: userSettings.fontSize)
        } else {
            // Remake the font size if it doesn't exist: This is exclusively for instances where the user deletes it
            userSettings = UserSettings()
            // Add it to Realm
//            let realm = try! Realm()
            RealmHelper.sharedInstance.save(userSettings) { saved in
                //
            }
            sliderControl(state: 100)
        }
        
        webView.reload()
    }
    
    func sliderControl(state: Int){
        switch state {
        case 75:
            fontSlider.setValue(0.75, animated: false)
            fontNumber = 75
            fontSizeLabel = "Small"
        case 100:
            fontSlider.setValue(1.1, animated: false)
            fontNumber = 100
            fontSizeLabel = "Regular"
        case 150:
            fontSlider.setValue(1.4, animated: false)
            fontNumber = 150
            fontSizeLabel = "Large"
        case 175:
            fontSlider.setValue(1.75, animated: false)
            fontNumber = 175
            fontSizeLabel = "ExtraLarge"
        default:
            fontSlider.setValue(1.1, animated: false)
            fontNumber = 100
            fontSizeLabel = "Regular"
        }
        fontSize.text = "Font Size: \(fontSizeLabel)"
    }
    
    init() {
        super.init(nibName: "FontSettingsView", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configView() {
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = .black.withAlphaComponent(0.5)
        self.backView.alpha = 0
        self.contentView.alpha = 0
    }
    
    func displayPopUp(sender: UIViewController) {
        sender.present(self, animated: false) {
            self.show()
        }
    }
    
    private func show() {
        UIView.animate(withDuration: 0.2, delay: 0.1) {
            self.backView.alpha = 1
            self.contentView.alpha = 1
        }
    }
    
    private func hide() {
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut) {
            self.backView.alpha = 0
            self.view.alpha = 0
        } completion: { _ in
            self.dismiss(animated: true)
        }
    }

}
