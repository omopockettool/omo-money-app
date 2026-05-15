import Foundation

enum HeroAmountInputSanitizer {
    static let maxIntegerDigits = 7
    static let maxDecimalDigits = 2

    static func sanitize(_ input: String) -> String {
        if input.isEmpty { return input }

        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        var filtered = input.filter { char in
            char.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
        }

        filtered = filtered.replacingOccurrences(of: ",", with: ".")

        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            filtered = components[0] + "." + components[1...].joined()
        }

        let parts = filtered.components(separatedBy: ".")
        var integerPart = parts[0]
        var decimalPart = parts.count > 1 ? parts[1] : ""

        if integerPart.count > maxIntegerDigits {
            integerPart = String(integerPart.prefix(maxIntegerDigits))
        }

        if decimalPart.count > maxDecimalDigits {
            decimalPart = String(decimalPart.prefix(maxDecimalDigits))
        }

        if parts.count > 1 {
            return integerPart + "." + decimalPart
        } else {
            return integerPart
        }
    }
}
