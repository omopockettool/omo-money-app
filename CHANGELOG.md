# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Complete MVVM architecture implementation
- Background queue optimization for Core Data operations
- NavigationStack implementation for modern iOS navigation
- Strict separation of business logic and UI components

### Changed
- Optimized all ViewModels with @MainActor for UI thread safety
- Improved error handling and validation across all components
- Enhanced performance with background Core Data operations

### Fixed
- All compilation errors related to optional types
- Removed duplicate Core Data files
- Cleaned up unused directories and files

## [0.2.0] - 2025-08-11

### Added
- **User Management UI**: Complete CRUD operations for User entity
  - UserListView with list display
  - AddUserView for creating new users
  - EditUserView for modifying existing users
  - UserRowView for individual user display
- **Navigation Structure**: MainView with NavigationStack
- **Core Data Integration**: All entities properly configured
- **Error Handling**: Comprehensive error messages and validation

### Changed
- Refactored from sheet-based navigation to NavigationStack
- Implemented strict MVVM architecture
- Optimized for native iOS performance

### Fixed
- Resolved all Core Data code generation conflicts
- Fixed optional type handling in all ViewModels
- Cleaned up duplicate and unused files

## [0.1.0] - 2025-08-11

### Added
- **Core Data Foundation**: Complete data model implementation
  - Category entity with color and group relationships
  - Entry entity with date and description support
  - Group entity with currency and member management
  - Item entity with amount and quantity tracking
  - User entity with email and name management
  - UserGroup entity with role-based permissions
- **ViewModels**: Full CRUD operations for all entities
  - CategoryViewModel with filtering and validation
  - EntryViewModel with date filtering and totals
  - GroupViewModel with member counting and sorting
  - ItemViewModel with amount calculations
  - UserViewModel with email validation
  - UserGroupViewModel with role management
- **Project Structure**: Organized Model/, ViewModel/, and View/ directories
- **Configuration Files**: TODO.md, LICENSE, .gitignore, README.md

### Technical Details
- Swift 5.9+ compatibility
- iOS 16+ target
- Core Data with proper delete rules
- MVVM architecture with ObservableObject
- Identifiable protocol implementation
- Comprehensive error handling
- Input validation and business rules

## [0.0.1] - 2024-12-19

### Added
- Initial project setup
- Basic project structure
- Core Data model file
- Basic SwiftUI app template
