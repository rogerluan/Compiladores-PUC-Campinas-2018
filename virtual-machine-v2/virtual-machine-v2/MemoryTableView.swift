//
//  MemoryTableView.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 22/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation
import UIKit

final class MemoryTableView : UITableView {
    var memory: [Int] = [] { didSet { handleMemoryChanged() } }

    // MARK: Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        dataSource = self
    }

    // MARK: Update
    private func handleMemoryChanged() {
        reloadData()
    }
}

extension MemoryTableView : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MemoryCell.reuseIdentifier, for: indexPath) as! MemoryCell
        cell.value = memory[indexPath.row]
        cell.index = indexPath.row
        return cell;
    }
}

extension MemoryTableView : UITableViewDelegate {

    // TODO: Implement
}
