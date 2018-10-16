//
//  DocumentPickerError.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 03/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class DocumentPickerError : Error {
    let message: String

    init(_ message: String) {
        self.message = message
    }
}
