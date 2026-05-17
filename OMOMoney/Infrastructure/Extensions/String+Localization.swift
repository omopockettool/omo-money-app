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
        static let retry = "general.retry"
        static let empty = "general.empty"
        static let paste = "general.paste"
        static let all = "general.all"
        static let pending = "general.pending"
        static let daily = "general.daily"
        static let weekly = "general.weekly"
        static let monthly = "general.monthly"
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
        static let namePlaceholder = "user.name.placeholder"
        static let emailPlaceholder = "user.email.placeholder"
        static let noEmail = "user.noEmail"
        static let profile = "user.profile"
        static let info = "user.info"
        static let details = "user.details"
        static let createdAt = "user.createdAt"
        static let updatedAt = "user.updatedAt"
        enum Welcome {
            static let title = "user.welcome.title"
            static let subtitle = "user.welcome.subtitle"
            static let legalIntro = "user.welcome.legalIntro"
            static let terms = "user.welcome.terms"
            static let privacy = "user.welcome.privacy"
            static let consent = "user.welcome.consent"
        }
    }
    
    // MARK: - Group
    enum Group {
        static let title = "group.title"
        static let singularTitle = "group.singularTitle"
        static let name = "group.name"
        static let currency = "group.currency"
        static let create = "group.create"
        static let edit = "group.edit"
        static let deleteConfirm = "group.delete.confirm"
        static let emptyMessage = "group.empty.message"
        static let members = "group.members"
        static let selectGroup = "group.selectGroup"
        static let deleting = "group.deleting"
        static let deleteWarning = "group.deleteWarning"
        static let deleteConfirmTitle = "group.deleteConfirmTitle"
        static let details = "group.details"
        static let info = "group.info"
        static let settings = "group.settings"
        static let content = "group.content"
        static let currencyEuro = "group.currencyEuro"
        static let currencyDollar = "group.currencyDollar"
        static let optionsFor = "group.optionsFor"
        static let holdForActions = "group.holdForActions"
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
        static let selectCategory = "category.selectCategory"
        static let emptyHint = "category.emptyHint"
        static let icon = "category.icon"
        static let new = "category.new"
        static let noLimit = "category.noLimit"
        static let limitFrequency = "category.limitFrequency"
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
        static let newEntry = "entry.newEntry"
        static let concept = "entry.concept"
        static let viewLess = "entry.viewLess"
        static let moreDetails = "entry.moreDetails"
        static let tapToAdd = "entry.tapToAdd"
        static let addByDate = "entry.addByDate"
        static let more = "entry.more"
    }
    
    // MARK: - Item
    enum Item {
        static let description = "item.description"
        static let quantity = "item.quantity"
        static let amount = "item.amount"
        static let total = "item.total"
        static let add = "item.add"
        static let newItem = "item.newItem"
        static let editItem = "item.editItem"
        static let subtotal = "item.subtotal"
        static let units = "item.units"
        static let loading = "item.loading"
        static let tapToAdd = "item.tapToAdd"
        static let costOf = "item.costOf"
        static let oneItem = "item.oneItem"
        static let items = "item.items"
        static let unpaid = "item.unpaid"
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
        static let selectPayment = "payment.selectPayment"
        static let emptyHint = "payment.emptyHint"
        static let none = "payment.none"
        static let cards = "payment.cards"
        static let cash = "payment.cash"
        static let transfers = "payment.transfers"
        static let digitalWallets = "payment.digitalWallets"
        static let digital = "payment.digital"
        static let others = "payment.others"
        static let card = "payment.card"
        static let other = "payment.other"
        static let debit = "payment.debit"
        static let credit = "payment.credit"
        static let transfer = "payment.transfer"
        static let icon = "payment.icon"
        static let newMethod = "payment.newMethod"
        static let editMethod = "payment.editMethod"
    }
    
    // MARK: - Dashboard
    enum Dashboard {
        static let title = "dashboard.title"
        static let totalExpenses = "dashboard.totalExpenses"
        static let totalIncome = "dashboard.totalIncome"
        static let balance = "dashboard.balance"
        static let thisMonth = "dashboard.thisMonth"
        static let recentEntries = "dashboard.recentEntries"
        static let changingGroup = "dashboard.changingGroup"
        static let today = "dashboard.today"
        static let yesterday = "dashboard.yesterday"
        static let costThisMonth = "dashboard.costThisMonth"
        static let costToday = "dashboard.costToday"
        static let added = "dashboard.added"
        static let filters = "dashboard.filters"
        static let itemStatus = "dashboard.itemStatus"
        static let month = "dashboard.month"
        static let year = "dashboard.year"
        static let clearFilters = "dashboard.clearFilters"
        static let noMatchesTitle = "dashboard.noMatchesTitle"
        static let noMatchesMessage = "dashboard.noMatchesMessage"
        static let searchItemSummarySingle = "dashboard.searchItemSummary.single"
        static let searchItemSummaryMultiple = "dashboard.searchItemSummary.multiple"
        static let emptyEntryToast = "dashboard.emptyEntryToast"
        static let markedAllPaid = "dashboard.markedAllPaid"
        static let markedAllPending = "dashboard.markedAllPending"
        static let changeUndone = "dashboard.changeUndone"
        static let undo = "dashboard.undo"
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = "settings.title"
        static let language = "settings.language"
        static let currency = "settings.currency"
        static let theme = "settings.theme"
        static let notifications = "settings.notifications"
        static let about = "settings.about"
        static let account = "settings.account"
        static let aboutOMO = "settings.aboutOMO"
        static let requiredConfig = "settings.requiredConfig"
        static let requiredConfigMsg = "settings.requiredConfigMsg"
        static let goToSettings = "settings.goToSettings"
        static let backup = "settings.backup"
        static let backupDescription = "settings.backupDescription"
        static let exportBackup = "settings.exportBackup"
        static let importBackup = "settings.importBackup"
        static let rescueBackupTitle = "settings.rescueBackupTitle"
        static let rescueBackupMessage = "settings.rescueBackupMessage"
        static let rescueBackupConfirm = "settings.rescueBackupConfirm"
        static let replaceDataTitle = "settings.replaceDataTitle"
        static let replaceDataMessage = "settings.replaceDataMessage"
        static let replaceDataConfirm = "settings.replaceDataConfirm"
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

    // MARK: - About
    enum About {
        static let application = "about.application"
        static let currentVersion = "about.currentVersion"
        static let whatsNew = "about.whatsNew"
        static let viewHistory = "about.viewHistory"
        static let title = "about.title"
        static let descriptionLabel = "about.descriptionLabel"
        static let tagline = "about.tagline"
        static let heroTagline = "about.heroTagline"
        static let officialWeb = "about.officialWeb"
        static let contact = "about.contact"
        static let support = "about.support"
        static let supportQuestion = "about.supportQuestion"
        static let supportDescription = "about.supportDescription"
        static let donate = "about.donate"
        static let developedBy = "about.developedBy"
        static let team = "about.team"
        static let motto = "about.motto"
        static let installed = "about.installed"
        static let changelog = "about.changelog"
        static let news = "about.news"
        static let shareApp = "about.shareApp"
        static let shareAppSubtitle = "about.shareAppSubtitle"
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
