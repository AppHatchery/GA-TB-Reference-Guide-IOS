//
//  ContentSizedTableView.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 9/15/21.
//

import UIKit

final class ContentSizedTableView: UITableView {
    
    override var contentSize:CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }

}
