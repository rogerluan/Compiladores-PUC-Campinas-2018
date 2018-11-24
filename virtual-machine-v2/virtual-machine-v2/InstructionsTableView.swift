//
//  SourceCodeTableView.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 08/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation
import UIKit

final class InstructionsTableView : UITableView {
    var items: [Instruction] = [] { didSet { handleItemsChanged() } }
    var index: Int = 0 { didSet { handleIndexChanged() } }
    var lineStoppedAt: Int = -1 { didSet { handleLineStoppedChanged() } }

    // MARK: Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        dataSource = self
    }

    // MARK: Update
    private func handleItemsChanged() {
        reloadData() // Inefficient but whatever (for now)
    }

    private func handleLineStoppedChanged() {
        reloadData() // Inefficient but whatever (for now)
    }

    private func handleIndexChanged() {
        let indexPath = IndexPath(row: index, section: 0)
        scrollToRow(at: indexPath, at: .middle, animated: true)
    }
}

extension InstructionsTableView : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InstructionCell.reuseIdentifier, for: indexPath) as! InstructionCell
        cell.line = indexPath.row // Must be called before setting the item
        cell.item = items[indexPath.row]
        cell.backgroundColor = indexPath.row == lineStoppedAt ? UIColor.blue.withAlphaComponent(0.2) : .clear
        return cell;
    }
}

extension InstructionsTableView : UITableViewDelegate {

    // TODO: Implement
}


//extension SourceCodeTableView : UITableViewDelegate {
//
//    // Display customization
//    optional public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
//    optional public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
//    optional public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
//
//    // Variable height support
//    optional public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
//    optional public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
//    optional public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
//
//
//    // Use the estimatedHeight methods to quickly calcuate guessed values which will allow for fast load times of the table.
//    // If these methods are implemented, the above -tableView:heightForXXX calls will be deferred until views are ready to be displayed, so more expensive logic can be placed there.
//    optional public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
//    optional public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
//    optional public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat
//
//
//    // Section header & footer information. Views are preferred over title should you decide to provide both
//    optional public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? // custom view for header. will be adjusted to default or specified header height
//    optional public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? // custom view for footer. will be adjusted to default or specified footer height
//    optional public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath)
//
//    // Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
//    optional public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
//    optional public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath?
//
//    // Called after the user changes the selection.
//    optional public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
//    optional public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
//
//
//    // Focus
//    optional public func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool
//    optional public func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool
//    optional public func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
//    optional public func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath?
//}
