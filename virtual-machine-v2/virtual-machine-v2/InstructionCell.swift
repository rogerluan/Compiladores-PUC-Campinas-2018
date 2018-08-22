//
//  InstructionCell.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 22/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import UIKit

final class InstructionCell : UITableViewCell {
    @IBOutlet private var breakpointButton: UIButton!
    @IBOutlet private var label: UILabel!

    static let reuseIdentifier = "InstructionCell"

    var item: Instruction! = nil { didSet { handleItemChanged() } }
    var isBreakpointSelected : Bool { return breakpointButton.isSelected }

    // MARK: Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        // TODO: get assets
//        breakpointButton.setImage(<#T##image: UIImage?##UIImage?#>, for: .normal)
//        breakpointButton.setImage(<#T##image: UIImage?##UIImage?#>, for: .selected)
    }

    // MARK: Update
    private func handleItemChanged() {
        label.text = "\(item.opcode) \(item.argument1) \(item.argument2)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = ""
        breakpointButton.isSelected = false
    }

    // MARK: Interaction
    @IBAction private func handleBreakpointSelected(sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
}
