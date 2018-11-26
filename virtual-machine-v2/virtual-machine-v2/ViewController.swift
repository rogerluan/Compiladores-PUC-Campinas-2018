//
//  ViewController.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 08/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    // MARK: Components
    @IBOutlet private var sourceTextView: UITextView!
    @IBOutlet private var lineNumberTextView: UITextView!
    @IBOutlet private var instructionsTableView: InstructionsTableView!
    @IBOutlet private var memoryTableView: MemoryTableView!

    @IBOutlet private var inputTextView: UITextView!
    @IBOutlet private var outputTextView: UITextView!
    @IBOutlet private var inputTextField: UITextField!
    @IBOutlet private var debugAreaContainer: UIView!

    @IBOutlet private var codeAndDebugStackView: UIStackView!
    @IBOutlet private var codeStackView: UIStackView!
    @IBOutlet private var mainStackView: UIStackView!
    @IBOutlet private var debugAreaButtonsStackView: UIStackView!
    @IBOutlet private var ioStackView: UIStackView!

    @IBOutlet private var exportButton: UIButton!
    @IBOutlet private var leftPanelToggleButton: UIButton!
    @IBOutlet private var bottomPanelToggleButton: UIButton!
    @IBOutlet private var rightPanelToggleButton: UIButton!
    @IBOutlet private var continueExecutionButton: UIButton!
    @IBOutlet private var debugAreaLeftPanelToggleButton: UIButton!
    @IBOutlet private var debugAreaRightPanelToggleButton: UIButton!
    @IBOutlet private var inputSubmissionButton: UIButton!

    // MARK: Settings
    private let showDebugAreaLeftPanelOnLaunch = true
    private let showLeftPanelOnLaunch = true
    private let showRightPanelOnLaunch = true

    private var previousNumberOfLines = 0
    private var screenSettings: [String] = []
    private var rawInstructions = "" { didSet { exportButton.isEnabled = !rawInstructions.isEmpty  } }
    private var sourceTextViewText: String? {
        get { return sourceTextView.text }
        set {
            sourceTextView.text = newValue?.trimmingCharacters(in: .whitespacesAndNewlines)
            screenSettings.append(sourceTextView.text ?? "") // Do this here so it only tracks programmatically set text changes
            handleSourceTextViewTextChanged()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Engine.shared.finishHandler = {
            print("Finished executing with success.")
        }
        Engine.shared.readHandler = { [unowned self] in
            self.inputTextField.isUserInteractionEnabled = true
            self.inputSubmissionButton.isEnabled = true
            self.inputTextField.becomeFirstResponder()
        }
        Engine.shared.printHandler = { [unowned self] value in
            self.println("\(value)")
        }
        Engine.shared.memoryChangedHandler = { [unowned self] in
            self.memoryTableView.handleMemoryChanged()
        }
        Engine.shared.programCounterChangedHandler = { [unowned self] index in
            self.instructionsTableView.index = index
        }
        Engine.shared.executionPausedHandler = { [unowned self] line in
            self.continueExecutionButton.isEnabled = true
            self.instructionsTableView.lineStoppedAt = line
        }

        // Set up initial layout
        inputTextView.text = nil
        outputTextView.text = nil
        inputTextView.isHidden = !showDebugAreaLeftPanelOnLaunch
        debugAreaLeftPanelToggleButton.isSelected = showDebugAreaLeftPanelOnLaunch

        instructionsTableView.isHidden = !showLeftPanelOnLaunch
        leftPanelToggleButton.isSelected = showLeftPanelOnLaunch

        memoryTableView.isHidden = !showRightPanelOnLaunch
        rightPanelToggleButton.isSelected = showRightPanelOnLaunch

        // Remove annoying iPad input assistant item bar
        for textView in [ sourceTextView, lineNumberTextView, inputTextView ] {
            textView?.autocorrectionType = .no
            textView?.inputAssistantItem.leadingBarButtonGroups = []
            textView?.inputAssistantItem.trailingBarButtonGroups = []
        }
        inputTextField.autocorrectionType = .no
        inputTextField.inputAssistantItem.leadingBarButtonGroups = []
        inputTextField.inputAssistantItem.trailingBarButtonGroups = []
    }

    @IBAction func openFilePicker(_ sender: UIButton) {
        documentPicker.show(from: self)
    }

    private lazy var documentPicker = DocumentPicker { [weak self] text, error in
        guard let self = self else { return }
        if let text = text {
            self.sourceTextViewText = text
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Failed to Open Document", comment: ""), message: error?.message ?? NSLocalizedString("An unknown error occurred.", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }

    @IBAction func run(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("How would you like to run this code?", comment: ""), message: nil, preferredStyle: .actionSheet)
        let stepByStepAction = UIAlertAction(title: NSLocalizedString("Step by step", comment: ""), style: .default) { [unowned self] _ in self.testAnalyzers(stepByStep: true) }
        let freeRunningAction = UIAlertAction(title: NSLocalizedString("Free Running", comment: ""), style: .default) { [unowned self] _ in self.testAnalyzers(stepByStep: false) }
        alert.addAction(stepByStepAction)
        alert.addAction(freeRunningAction)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = CGRect(x: sender.bounds.midX, y: sender.bounds.maxY, width: 0, height: 0)
        }
        present(alert, animated: true, completion: nil)
    }

    @IBAction func exportAssemblyCode() {
        let shareActivity = UIActivityViewController(activityItems: [ rawInstructions ], applicationActivities: nil)
        if let popoverController = shareActivity.popoverPresentationController {
            popoverController.sourceView = exportButton
            popoverController.sourceRect = CGRect(x: exportButton.bounds.midX, y: exportButton.bounds.maxY, width: 0, height: 0)
        }
        present(shareActivity, animated: true, completion: nil)
    }

    // ===========================
    // Debugging area
    private func testAnalyzers(stepByStep: Bool) {
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: sourceTextView.text ?? ""), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            do {
                let instructions = try syntacticAnalyzer.analyzeProgram()
                rawInstructions = syntacticAnalyzer.rawInstructions()
                println(NSLocalizedString("✅ Lexical, Syntactic and Semantic Analysis Completed with No Errors", comment: ""))
                testVirtualMachine(instructions: instructions, stepByStep: stepByStep)
            } catch {
                let error = error as! CompilerError
                println(error.message)
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

    /// Reads and processes instructions from the text view.
    private func testVirtualMachine(instructions: [Instruction], stepByStep: Bool) {
        guard !instructions.isEmpty else {
            let alert = UIAlertController(title: NSLocalizedString("Failed to Compile", comment: ""), message: NSLocalizedString("The source code failed to compile or returned no instructions.", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        instructionsTableView.items = instructions
        do {
            try Engine.shared.execute(instructions: instructions, stepByStep: stepByStep)
        } catch {
            let error = error as! RuntimeError
            println(error.message)
            print(error.message)
            let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }

    // ===========================

    @IBAction func continueExecution() {
        continueExecutionButton.isEnabled = false
        instructionsTableView.lineStoppedAt = -1
        do {
            try Engine.shared.continueExecution()
        } catch {
            let error = error as! RuntimeError
            println(error.message)
            print(error.message)
            let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: nil)
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
    }

    // MARK: Actions
    @IBAction func toggleShowLeftPanel(_ sender: UIButton) {
        sender.isSelected.toggle()
        UIView.animate(withDuration: 0.25) {
            self.instructionsTableView.isHidden.toggle()
            self.codeStackView.layoutIfNeeded()
        }
    }

    @IBAction func toggleShowBottomPanel(_ sender: UIButton) {
        sender.isSelected.toggle()
        UIView.animate(withDuration: 0.25) {
            self.debugAreaContainer.isHidden.toggle()
            self.codeAndDebugStackView.layoutIfNeeded()
        }
    }

    @IBAction func toggleShowRightPanel(_ sender: UIButton) {
        sender.isSelected.toggle()
        UIView.animate(withDuration: 0.25) {
            self.memoryTableView.isHidden.toggle()
            self.mainStackView.layoutIfNeeded()
        }
    }

    @IBAction func toggleShowDebugAreaLeftPanel(_ sender: UIButton) {
        sender.isSelected.toggle()
        if !sender.isSelected && outputTextView.isHidden {
            toggleShowDebugAreaRightPanel(debugAreaRightPanelToggleButton)
        }
        UIView.animate(withDuration: 0.25) {
            self.inputTextView.isHidden.toggle()
            self.ioStackView.layoutIfNeeded()
        }
    }

    @IBAction func toggleShowDebugAreaRightPanel(_ sender: UIButton) {
        sender.isSelected.toggle()
        if !sender.isSelected && inputTextView.isHidden {
            toggleShowDebugAreaLeftPanel(debugAreaLeftPanelToggleButton)
        }
        UIView.animate(withDuration: 0.25) {
            self.outputTextView.isHidden.toggle()
            self.ioStackView.layoutIfNeeded()
        }
    }
    
    @IBAction func submitInputValue() {
        guard inputTextField.isUserInteractionEnabled else { return }
        guard let decimalString = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !decimalString.isEmpty, let valueRead = Decimal(string: decimalString) else {
            let alert = UIAlertController(title: NSLocalizedString("Failed to Read Value", comment: ""), message: NSLocalizedString("The value read can't be represented as a number. Please try again.", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .cancel, handler: { [unowned self] _ in
                self.inputTextField.becomeFirstResponder()
            })
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
            return
        }
        // Append input text to the input text view
        inputTextView.text += "\(decimalString)\n"
        // Scroll to bottom
        let bottom = NSMakeRange(inputTextView.text.count - 1, 1)
        inputTextView.scrollRangeToVisible(bottom)

        inputTextField.text = nil
        inputTextField.resignFirstResponder()
        inputTextField.isUserInteractionEnabled = false
        inputSubmissionButton.isEnabled = false
        Engine.shared.setValueRead(valueRead)
    }

    // Convenience
    // TODO: Improve lagg when calculating the lineNumberTextView text
    // TODO: Improve the delay that it takes to update the lineNumberTextView text when entering new blank lines
    private func handleSourceTextViewTextChanged() {
        let string = sourceTextViewText ?? ""
        var numberOfLines: Int = 0
        var index: String.Index = string.startIndex
        while index < string.endIndex {
            numberOfLines += 1
            index = string.lineRange(for: index..<index).upperBound
        }
        // This guard statement reduces lagg.
        guard previousNumberOfLines != numberOfLines else { return }
        previousNumberOfLines = numberOfLines
        lineNumberTextView.text = ""
        guard numberOfLines > 0 else { return }
        for i in 1...numberOfLines {
            lineNumberTextView.text += "\(i)\n"
        }
    }

    private func println(_ string: String) {
        // Append text and add line break
        outputTextView.text += "\(string)\n"
        // Scroll to bottom
        let bottom = NSMakeRange(outputTextView.text.count - 1, 1)
        outputTextView.scrollRangeToVisible(bottom)
    }
}

extension ViewController : UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView {
        case sourceTextView: handleSourceTextViewTextChanged()
        default:
            if text == "\n" {
                textView.resignFirstResponder()
            }
        }
        return true
    }
}

extension ViewController : UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case inputTextField: submitInputValue()
        default: break
        }
        return true
    }
}

extension ViewController : UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        switch scrollView {
        case sourceTextView:
            // Make the line number follow the content offset of the source text view
            lineNumberTextView.contentOffset = sourceTextView.contentOffset
        default: break
        }
    }
}
