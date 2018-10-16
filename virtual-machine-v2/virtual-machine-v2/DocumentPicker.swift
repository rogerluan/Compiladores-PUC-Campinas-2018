//
//  DocumentPicker.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 03/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

final class DocumentPicker : NSObject, UIDocumentPickerDelegate {
    private let didPickFileText: ((String?, DocumentPickerError?) -> Void)

    init(fileTextPickedHandler: @escaping ((String?, DocumentPickerError?) -> Void)) {
        didPickFileText = fileTextPickedHandler
        super.init()
    }

    // Presentation
    func show(from viewController: UIViewController) {
        let picker = UIDocumentPickerViewController(documentTypes: [ kUTTypeText as String,
                                                                     kUTTypePlainText as String,
                                                                     kUTTypeUTF8PlainText as String,
                                                                     kUTTypeUTF16ExternalPlainText as String,
                                                                     kUTTypeUTF16ExternalPlainText as String,
                                                                     kUTTypeUTF16PlainText as String,
                                                                     kUTTypeRTF as String ], in: .import)
        picker.zlDocumentPicker = self
        picker.delegate = self
        viewController.present(picker, animated: true, completion: nil)
    }

    // MARK: UIDocumentPicker Delegate Methods
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { didPickFileText(nil, DocumentPickerError(NSLocalizedString("Failure loading document.", comment: ""))); return }
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let string = try? String(contentsOf: url) else { self?.didPickFileText(nil, DocumentPickerError(NSLocalizedString("Failed to load document content. Is this a valid text file?", comment: ""))); return }
            DispatchQueue.main.async {
                self?.didPickFileText(string, nil)
            }
        }
    }
}

// Declare a global var to produce a unique address as the associated object handle
var documentPickerAssociatedObjectHandler: UInt8 = 0
var documentMenuAssociatedObjectHandler: UInt8 = 0

fileprivate extension UIDocumentPickerViewController {
    var zlDocumentPicker: DocumentPicker {
        get { return objc_getAssociatedObject(self, &documentPickerAssociatedObjectHandler) as! DocumentPicker }
        set { objc_setAssociatedObject(self, &documentPickerAssociatedObjectHandler, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

