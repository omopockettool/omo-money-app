//
//  NSDecimalNumber+Safe.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation

extension NSDecimalNumber {
    
    /// Safe addition that prevents NaN values
    /// - Parameter value: The value to add
    /// - Returns: Safe result or zero if operation would result in NaN
    func safeAdd(_ value: NSDecimalNumber) -> NSDecimalNumber {
        // Check if either value is NaN or invalid
        if self == NSDecimalNumber.notANumber || value == NSDecimalNumber.notANumber {
            return NSDecimalNumber.zero
        }
        
        // Perform addition
        let result = self.adding(value)
        
        // Check if result is NaN
        if result == NSDecimalNumber.notANumber {
            return NSDecimalNumber.zero
        }
        
        return result
    }
    
    /// Check if the value is valid (not NaN)
    var isValid: Bool {
        return self != NSDecimalNumber.notANumber
    }
}
