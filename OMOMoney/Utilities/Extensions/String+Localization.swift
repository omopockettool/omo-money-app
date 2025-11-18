//
//  String+Localization.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

// MARK: - String Localization Extension
extension String {
    /// Returns the localized string for the current key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns the localized string with format arguments
    /// - Parameter arguments: Format arguments to be inserted into the localized string
    /// - Returns: Formatted localized string
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    /// Returns the localized string with a specific comment
    /// - Parameter comment: Comment describing the string's usage
    /// - Returns: Localized string
    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

// MARK: - Localization Keys
/// Centralized localization keys to avoid string literals
enum LocalizationKey {
    
    // MARK: - General
    enum General {
        static let appName = "app.name"
        static let ok = "general.ok"
        static let cancel = "general.cancel"
        static let save = "general.save"
        static let delete = "general.delete"
        static let edit = "general.edit"
        static let add = "general.add"
        static let back = "general.back"
        static let done = "general.done"
        static let error = "general.error"
        static let loading = "general.loading"
        static let search = "general.search"
        static let close = "general.close"
    }
    
    // MARK: - Navigation
    enum Navigation {
        static let dashboard = "nav.dashboard"
        static let groups = "nav.groups"
        static let categories = "nav.categories"
        static let entries = "nav.entries"
        static let settings = "nav.settings"
        static let users = "nav.users"
    }
    
    // MARK: - User
    enum User {
        static let title = "user.title"
        static let name = "user.name"
        static let email = "user.email"
        static let create = "user.create"
        static let edit = "user.edit"
        static let deleteConfirm = "user.delete.confirm"
        static let emptyMessage = "user.empty.message"
    }
    
    // MARK: - Group
    enum Group {
        static let title = "group.title"
        static let name = "group.name"
        static let currency = "group.currency"
        static let create = "group.create"
        static let edit = "group.edit"
        static let deleteConfirm = "group.delete.confirm"
        static let emptyMessage = "group.empty.message"
        static let members = "group.members"
    }
    
    // MARK: - Category
    enum Category {
        static let title = "category.title"
        static let name = "category.name"
        static let color = "category.color"
        static let limit = "category.limit"
        static let create = "category.create"
        static let edit = "category.edit"
        static let deleteConfirm = "category.delete.confirm"
        static let emptyMessage = "category.empty.message"
    }
    
    // MARK: - Entry
    enum Entry {
        static let title = "entry.title"
        static let description = "entry.description"
        static let date = "entry.date"
        static let amount = "entry.amount"
        static let category = "entry.category"
        static let paymentMethod = "entry.paymentMethod"
        static let create = "entry.create"
        static let edit = "entry.edit"
        static let deleteConfirm = "entry.delete.confirm"
        static let emptyMessage = "entry.empty.message"
    }
    
    // MARK: - Item
    enum Item {
        static let description = "item.description"
        static let quantity = "item.quantity"
        static let amount = "item.amount"
        static let total = "item.total"
        static let add = "item.add"
    }
    
    // MARK: - Payment Method
    enum Payment {
        static let title = "payment.title"
        static let name = "payment.name"
        static let type = "payment.type"
        static let active = "payment.active"
        static let create = "payment.create"
        static let edit = "payment.edit"
        static let deleteConfirm = "payment.delete.confirm"
        static let emptyMessage = "payment.empty.message"
    }
    
    // MARK: - Dashboard
    enum Dashboard {
        static let title = "dashboard.title"
        static let totalExpenses = "dashboard.totalExpenses"
        static let totalIncome = "dashboard.totalIncome"
        static let balance = "dashboard.balance"
        static let thisMonth = "dashboard.thisMonth"
        static let recentEntries = "dashboard.recentEntries"
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = "settings.title"
        static let language = "settings.language"
        static let currency = "settings.currency"
        static let theme = "settings.theme"
        static let notifications = "settings.notifications"
        static let about = "settings.about"
    }
    
    // MARK: - Validation Errors
    enum ValidationError {
        static let emptyName = "error.validation.emptyName"
        static let emptyEmail = "error.validation.emptyEmail"
        static let invalidEmail = "error.validation.invalidEmail"
        static let emptyGroupName = "error.validation.emptyGroupName"
        static let invalidAmount = "error.validation.invalidAmount"
        static let emptyItemDescription = "error.validation.emptyItemDescription"
        static let emptyCategoryName = "error.validation.emptyCategoryName"
        static let emptyPaymentMethodName = "error.validation.emptyPaymentMethodName"
    }
    
    // MARK: - Repository Errors
    enum RepositoryError {
        static let notFound = "error.repository.notFound"
        static let invalidData = "error.repository.invalidData"
        static let saveFailed = "error.repository.saveFailed"
        static let deleteFailed = "error.repository.deleteFailed"
    }
    
    // MARK: - Success Messages
    enum Success {
        static let created = "success.created"
        static let updated = "success.updated"
        static let deleted = "success.deleted"
        static let saved = "success.saved"
    }
}

// MARK: - Usage Example
/*
 // Simple usage:
 let title = "user.title".localized
 
 // Using the enum (type-safe):
 let title = LocalizationKey.User.title.localized
 
 // With format arguments:
 let message = "user.count".localized(with: userCount)
 
 // In SwiftUI:
 Text(LocalizationKey.User.title.localized)
 Text("user.title".localized)
 
 // Direct in SwiftUI (preferred):
 Text(LocalizationKey.User.title, bundle: .main)
 */
