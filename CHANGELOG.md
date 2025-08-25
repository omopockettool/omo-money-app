# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-08-12

### Added
- **Complete Navigation System**: Full NavigationStack + NavigationDestination implementation
- **Settings Navigation**: Tuerca button now navigates to SettingsView
- **Add Entry Navigation**: Add Entry button now navigates to AddEntryView
- **Navigation Enums**: SettingsDestination and AddEntryDestination for type-safe navigation
- **Centralized Navigation**: All NavigationDestination definitions in MainView
- **Programmatic Navigation**: Consistent navigationPath.append() pattern across all views

### Changed
- **Navigation Architecture**: Migrated from sheet-based to pure NavigationStack approach
- **Navigation Pattern**: Unified navigation using NavigationPath and NavigationDestination
- **Button Actions**: Updated all navigation buttons to use programmatic navigation
- **LoadingView Compatibility**: Fixed Color(.systemBackground) issues for macOS compatibility

### Fixed
- **Navigation Consistency**: All views now follow the same navigation pattern
- **Parameter Order**: Corrected AddEntryView init parameter order in MainView
- **Navigation State**: Centralized NavigationPath management in MainView
- **Return Navigation**: Proper navigationPath.removeLast() implementation

### Technical Improvements
- **Type-Safe Navigation**: Enum-based navigation destinations with associated values
- **NavigationStack Centralization**: Single source of truth for all navigation destinations
- **iOS 18.5+ Best Practices**: Modern NavigationStack implementation
- **Navigation Testing**: Verified all navigation flows work correctly

## [0.3.0] - 2025-08-12

### Added
- **Complete MVVM Architecture**: Full implementation with strict separation of concerns
- **Background Threading**: All Core Data operations now use background threads
- **Enhanced Debug System**: Comprehensive debugging tools for data persistence verification
- **CreateGroupView**: Complete group creation functionality with user ownership
- **Extensions**: Utility extensions for safe operations (NSDecimalNumber+Safe, User+Safe)
- **Async Operations**: Proper async/await support for complex workflows
- **Thread Safety**: @MainActor implementation across all ViewModels

### Changed
- **Performance Optimization**: Moved all CRUD operations to background threads
- **UI Responsiveness**: Main thread now exclusively reserved for UI updates
- **Error Handling**: Enhanced error propagation from background to main thread
- **Architecture**: Consistent threading pattern across all ViewModels
- **Navigation**: Improved group creation flow with proper async support

### Fixed
- **Threading Issues**: Eliminated main thread blocking during Core Data operations
- **UI Freezing**: Prevented UI freezes during database operations
- **Memory Management**: Proper weak self references and context management
- **Async Coordination**: Fixed CreateGroupView to work with new async ViewModels

### Technical Improvements
- **context.perform**: All ViewModels now use background context operations
- **Task + @MainActor**: Proper UI updates from background operations
- **Consistent Pattern**: Unified threading approach across all ViewModels
- **Performance**: Significant improvement in UI responsiveness
- **Debug Tools**: Added Refresh Data, Debug Data Persistence, and Test Group Creation Flow buttons

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
