import Foundation

/// Helper class for input validation
struct ValidationHelper {
    
    // MARK: - Name Validation
    static func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count >= AppConstants.Validation.minNameLength &&
               trimmedName.count <= AppConstants.Validation.maxNameLength
    }
    
    static func nameValidationMessage(_ name: String) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return "El nombre es requerido"
        }
        
        if trimmedName.count < AppConstants.Validation.minNameLength {
            return "El nombre debe tener al menos \(AppConstants.Validation.minNameLength) caracteres"
        }
        
        if trimmedName.count > AppConstants.Validation.maxNameLength {
            return "El nombre debe tener menos de \(AppConstants.Validation.maxNameLength) caracteres"
        }
        
        return nil
    }
    
    // MARK: - Email Validation
    static func isValidEmail(_ email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty { return true } // Email is optional
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: trimmedEmail)
    }
    
    static func emailValidationMessage(_ email: String) -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty { return nil } // Email is optional
        
        if !isValidEmail(trimmedEmail) {
            return "Por favor ingresa un email válido"
        }
        
        if trimmedEmail.count < AppConstants.Validation.minEmailLength {
            return "El email debe tener al menos \(AppConstants.Validation.minEmailLength) caracteres"
        }
        
        if trimmedEmail.count > AppConstants.Validation.maxEmailLength {
            return "El email debe tener menos de \(AppConstants.Validation.maxEmailLength) caracteres"
        }
        
        return nil
    }
    
    // MARK: - Currency Validation
    static func isValidCurrency(_ currency: String) -> Bool {
        return AppConstants.availableCurrencies.contains(currency)
    }
    
    static func currencyValidationMessage(_ currency: String) -> String? {
        if !isValidCurrency(currency) {
            return "Por favor selecciona una moneda válida"
        }
        return nil
    }
    
    // MARK: - Amount Validation
    static func isValidAmount(_ amount: NSDecimalNumber) -> Bool {
        return amount.compare(NSDecimalNumber.zero) != .orderedAscending
    }
    
    static func amountValidationMessage(_ amount: NSDecimalNumber) -> String? {
        if !isValidAmount(amount) {
            return "El monto debe ser mayor o igual a cero"
        }
        return nil
    }
}
