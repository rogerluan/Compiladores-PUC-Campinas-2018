//
//  MemoryCell.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 22/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import UIKit

final class MemoryCell : UITableViewCell {
    @IBOutlet private var indexLabel: UILabel!
    @IBOutlet private var valueLabel: UILabel!
    @IBOutlet private var indicatorImageView: UIImageView!

    static let reuseIdentifier = "MemoryCell"

    var index: Int! { didSet { handleIndexChanged() } }
    var value: Decimal! { didSet { handleValueChanged() } }
    var isCurrentIndex: Bool = false { didSet { handleIsCurrentIndexChanged() } }

    // MARK: Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: Update
    private func handleIndexChanged() {
        indexLabel.text = String(index)
    }

    private func handleValueChanged() {
        valueLabel.text = "\(value!)"
    }

    private func handleIsCurrentIndexChanged() {
        indicatorImageView.image = isCurrentIndex ? #imageLiteral(resourceName: "checkbox-checked") : nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        indexLabel.text = nil
        valueLabel.text = nil
        indicatorImageView.image = nil
    }
}
