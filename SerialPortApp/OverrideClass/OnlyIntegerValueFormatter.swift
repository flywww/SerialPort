//
//  OnlyIntegerValueFormatter.swift
//  SerialPortApp
//
//  Created by 林盈志 on 29/03/2017.
//  Copyright © 2017 ST004. All rights reserved.
//

import Cocoa

class OnlyIntegerValueFormatter: NumberFormatter {

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }
        // Actual check
        return Int(partialString) != nil
    }
}
