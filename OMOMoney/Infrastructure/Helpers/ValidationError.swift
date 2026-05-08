import Foundation

enum ValidationError: LocalizedError {
    case emptyName
    case emptyEmail
    case invalidEmail
    case emptyGroupName
    case invalidAmount
    case emptyItemDescription
    case emptyCategoryName
    case emptyPaymentMethodName
    case invalidRole
    case invalidDescription
    case invalidQuantity
    case invalidItemList
    case invalidGroup

    var errorDescription: String? {
        switch self {
        case .emptyName:               return "Name cannot be empty"
        case .emptyEmail:              return "Email cannot be empty"
        case .invalidEmail:            return "Email must be valid"
        case .emptyGroupName:          return "Group name cannot be empty"
        case .invalidAmount:           return "Amount must be greater than zero"
        case .emptyItemDescription:    return "Item description cannot be empty"
        case .emptyCategoryName:       return "Category name cannot be empty"
        case .emptyPaymentMethodName:  return "Payment method name cannot be empty"
        case .invalidRole:             return "Role cannot be empty"
        case .invalidDescription:      return "Description cannot be empty"
        case .invalidQuantity:         return "Quantity must be greater than zero"
        case .invalidItemList:         return "Invalid item list"
        case .invalidGroup:            return "Invalid group"
        }
    }
}
