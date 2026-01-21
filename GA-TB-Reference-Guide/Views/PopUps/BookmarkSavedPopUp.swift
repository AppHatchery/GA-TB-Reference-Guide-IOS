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

    init(
        frame: CGRect,
        bookmarkName: String,
        delegate: BookmarkSavedPopUpDelegate? = nil
    ) {
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
        let nibView =
            (Bundle.main.loadNibNamed(
                "BookmarkSavedPopUp",
                owner: self,
                options: nil
            )!.first as! UIView)
        self.addSubview(nibView)

        nibView.translatesAutoresizingMaskIntoConstraints = false

        nibView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        nibView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive =
            true
        nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive =
            true
        contentViewTopConstraint = nibView.topAnchor.constraint(
            equalTo: self.topAnchor
        )

        contentViewTopConstraint.isActive = true

        mainView.layer.cornerRadius = 4
        mainView.layer.masksToBounds = true

        contentLabel.setText(
            "Bookmarked! Now you can quickly access this content through My Bookmarks on Home page",
            highlightedStrings: ["My Bookmarks", "Home"]
        )
        
        configureVisitButton()
        configureDismissButton()

        visitButton.addTarget(
            self,
            action: #selector(visitButtonPressed),
            for: .touchUpInside
        )
        dismissButton.addTarget(
            self,
            action: #selector(dismissButtonPressed),
            for: .touchUpInside
        )
    }

    private func configureVisitButton() {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = "Visit"
            config.cornerStyle = .fixed
            config.baseForegroundColor = .label
            config.background.cornerRadius = 0

            visitButton.configuration = config
            visitButton.configurationUpdateHandler = { button in
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
            visitButton.layer.borderWidth = 0
            visitButton.layer.cornerRadius = 0
            visitButton.layer.masksToBounds = true
        }
    }

    private func configureDismissButton() {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()

            config.title = "Dismiss"
            config.cornerStyle = .fixed
            config.baseBackgroundColor = .colorPrimary
            config.baseForegroundColor = .white
            config.background.cornerRadius = 0

            dismissButton.configuration = config
        } else {
            dismissButton.layer.borderWidth = 0
            dismissButton.layer.cornerRadius = 0
            dismissButton.layer.masksToBounds = true
        }
    }

    @objc func visitButtonPressed() {
        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.backgroundView.alpha = 0
                self.mainView.transform = CGAffineTransform(
                    scaleX: 0.001,
                    y: 0.001
                )
            },
            completion: { _ in
                self.delegate?.didTapVisitBookmarks()
                self.removeFromSuperview()
            }
        )
    }

    @objc func dismissButtonPressed() {
        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                self.backgroundView.alpha = 0
                self.mainView.transform = CGAffineTransform(
                    scaleX: 0.001,
                    y: 0.001
                )
            },
            completion: { _ in
                self.removeFromSuperview()
            }
        )
    }

    // Convenience method to show the popup
    static func show(
        in window: UIWindow,
        bookmarkName: String,
        delegate: BookmarkSavedPopUpDelegate? = nil
    ) {
        let popup = BookmarkSavedPopUp(
            frame: window.bounds,
            bookmarkName: bookmarkName,
            delegate: delegate
        )
        popup.mainView.transform = CGAffineTransform(scaleX: 0, y: 0)
        popup.backgroundView.alpha = 0

        window.addSubview(popup)

        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: .curveEaseOut,
            animations: {
                popup.backgroundView.alpha = 0.5
                popup.mainView.transform = CGAffineTransform(
                    scaleX: 1.0,
                    y: 1.0
                )
            }
        )
    }
}
