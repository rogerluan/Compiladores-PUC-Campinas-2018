//
//  ViewController.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 08/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    @IBOutlet private var sourceTextView: UITextView!
    @IBOutlet private var instructionsTableView: InstructionsTableView!
    @IBOutlet private var inputTextView: UITextView!
    @IBOutlet private var outputTextView: UITextView!
    @IBOutlet private var inputTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func openFilePicker(_ sender: UIButton) {
        // TODO: Open iCloud Drive picker
    }

    @IBAction func run(_ sender: UIButton) {
        // TODO: guard against lack of file
        // TODO: run the file
        // TODO: Implement different run options (e.g. step by step, or free running)
    }

    @IBAction func pauseOrPlay(_ sender: UIButton) {
        // TODO: Detect if the current state is pause, or play, and execute the respective function
    }
}
