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
        cell.backgroundColor = indexPath.row == lineStoppedAt ? UIColor(red: 0.875, green: 0.933, blue: 0.961, alpha: 1) : .clear
        return cell;
    }
}
