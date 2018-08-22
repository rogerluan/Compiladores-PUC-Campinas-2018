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

    static let reuseIdentifier = "MemoryCell"

    var index: Int! { didSet { handleIndexChanged() } }
    var value: Int! { didSet { handleValueChanged() } }

    // MARK: Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: Update
    private func handleIndexChanged() {
        indexLabel.text = String(index + 1)
    }

    private func handleValueChanged() {
        valueLabel.text = String(value)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        indexLabel.text = ""
        valueLabel.text = ""
    }
}
