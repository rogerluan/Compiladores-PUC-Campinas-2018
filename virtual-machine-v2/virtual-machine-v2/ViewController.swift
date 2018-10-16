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
    @IBOutlet private var memoryTableView: MemoryTableView!

    @IBOutlet private var inputTextView: UITextView!
    @IBOutlet private var outputTextView: UITextView!
    @IBOutlet private var inputTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        Engine.shared.finishHandler = {
            print("Finished executing with success.")
        }
        Engine.shared.readHandler = { [unowned self] in
            self.inputTextView.isUserInteractionEnabled = true
            self.inputTextView.becomeFirstResponder()
        }
        Engine.shared.printHandler = { [unowned self] value in
            self.outputTextView.text = self.outputTextView.text.appending("\n\(value)")
        }
        Engine.shared.memoryChangedHandler = { [unowned self] memory in
            self.memoryTableView.memory = memory
        }
        Engine.shared.programCounterChangedHandler = { [unowned self] index in
            self.instructionsTableView.index = index
        }
    }

    @IBAction func openFilePicker(_ sender: UIButton) {
        // TODO: Open iCloud Drive picker
    }

    @IBAction func run(_ sender: UIButton) {
        // TODO: guard against lack of file
        // TODO: run the file
        // TODO: Implement different run options (e.g. step by step, or free running)
//        read()
        outputTextView.text = nil
        testSyntacticAnalyzer()
    }

    // ===========================
    // Debugging area
    private func testLexicalAnalyzer() {
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: sourceTextView.text ?? "") {
            do {
                while let nextToken = try lexicalAnalyzer.readNextToken() {
                    outputTextView.text = (outputTextView.text ?? "") + nextToken.debugDescription + "\n"
                    print(nextToken.debugDescription)
                }
            } catch {
                let errorMessage = (error as! LexicalError).message
                outputTextView.text = (outputTextView.text ?? "") + errorMessage
                print(errorMessage)
                let alert = UIAlertController(title: NSLocalizedString("Lexical Error", comment: ""), message: errorMessage, preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Lexical Error", comment: ""), message: NSLocalizedString("The file you loaded is empty.", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }

    private func testSyntacticAnalyzer() {
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: sourceTextView.text ?? ""), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            do {
                try syntacticAnalyzer.analyzeProgram()
                outputTextView.text = NSLocalizedString("✅ Lexical and Syntactic Analysis Completed with No Errors", comment: "")
            } catch {
                let error = error as! CompilerError
                outputTextView.text = (outputTextView.text ?? "") + error.message
                print(error.message)
                let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Lexical Error", comment: ""), message: NSLocalizedString("The file you loaded is empty.", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }

    // ===========================

    @IBAction func pauseOrPlay(_ sender: UIButton) {
        // TODO: Detect if the current state is pause, or play, and execute the respective function
    }

    /// Reads and processes instructions from the text view.
    private func read() {
        let instructions = Engine.shared.process(text: sourceTextView.text ?? "")
        guard !instructions.isEmpty else { showFailureAlert(); return }
        instructionsTableView.items = instructions
    }

    private func showFailureAlert() {
        let alert = UIAlertController(title: NSLocalizedString("Failed to Compile", comment: ""), message: NSLocalizedString("The source code failed to compile or returned no instructions.", comment: ""), preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController : UITextViewDelegate {

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let decimal = Decimal(string: textView.text) else {
            let alert = UIAlertController(title: NSLocalizedString("Failed to Read Value", comment: ""), message: NSLocalizedString("The value read can't be represented as a number. Please try again.", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: { _ in
                textView.becomeFirstResponder()
            })
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        Engine.shared.valueRead = decimal
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return true
    }
}
