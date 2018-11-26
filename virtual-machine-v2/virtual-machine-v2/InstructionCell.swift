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
    @IBOutlet private var indexLabel: UILabel!

    static let reuseIdentifier = "InstructionCell"

    var item: Instruction! = nil { didSet { handleItemChanged() } }
    var line: Int = 0

    // MARK: Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        breakpointButton.setImage(#imageLiteral(resourceName: "checkbox-unchecked"), for: .normal)
        breakpointButton.setImage(#imageLiteral(resourceName: "checkbox-checked"), for: .selected)
        breakpointButton.adjustsImageWhenHighlighted = false
    }

    // MARK: Update
    private func handleItemChanged() {
        label.text = {
            switch item {
            case .null(let label)?: return "\(label)\t\(item.opcode)"
            default: return "\t\(item.opcode) \(item.argument1 ?? "") \(item.argument2 ?? "")"
            }
        }()
        breakpointButton.isSelected = Engine.shared.hasBreakpoint(at: line)
        indexLabel.text = "\(line)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        breakpointButton.isSelected = false
    }

    // MARK: Interaction
    @IBAction private func handleBreakpointSelected(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        Engine.shared.setBreakpoint(active: sender.isSelected, at: line)
    }
}
