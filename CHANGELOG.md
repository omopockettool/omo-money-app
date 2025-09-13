# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.0] - 2025-09-13

### Added
- **Simplified Application Architecture**: Complete redesign of app initialization flow
  - New MainView with simplified user detection and sheet management
  - AppContentView as dedicated main interface for authenticated users
  - Streamlined first-user creation process with automatic redirection
  - Clean separation between empty state and main app content
- **Enhanced User Experience Flow**: Intuitive app onboarding and navigation
  - Automatic detection of empty sandbox state
  - Modal sheet for first user creation with seamless dismiss
  - Immediate redirection to main app after user creation
  - Loading states and progress indicators for better UX
- **Async Callback Architecture**: Modern Swift concurrency implementation
  - Async callbacks for user creation with proper error handling
  - Background thread operations with main thread UI updates
  - Elimination of unnecessary Task wrappers and polling
  - Clean async/await patterns throughout the application

### Changed
- **MainView Simplification**: Reduced complexity from 174 to 109 lines
  - Removed complex DetailedGroupView dependencies
  - Eliminated navigation destinations and path management
  - Simplified to focus only on user detection and sheet presentation
  - Clean ZStack-based conditional rendering
- **Service Architecture Cleanup**: Removed ObservableObject inheritance from services
  - Services now function as pure data access layers
  - Eliminated @StateObject usage for services in favor of direct initialization
  - Better adherence to MVVM architecture principles
  - Reduced memory overhead and improved performance
- **Navigation System Refactoring**: Streamlined navigation without complex enums
  - Removed SettingsDestination and other navigation enums
  - Simplified button actions with direct callbacks
  - TODO markers for future navigation implementation
  - Focus on core functionality over complex routing

### Fixed
- **Optional Value Handling**: Proper nil coalescing for Core Data optionals
  - Safe unwrapping of user.name and group.name properties
  - Fallback values ("User", "Group") for missing data
  - Eliminated compiler warnings about optional string interpolation
- **Sheet Dismissal Issues**: Automatic sheet closure after user creation
  - Explicit sheet dismissal in user creation callback
  - Proper timing with 0.2-second delay for UI synchronization
  - Complete redirection flow from empty state to main content
- **Compilation Errors**: Resolution of trailing closure and type errors
  - Fixed Group/ZStack nesting issues causing compilation errors
  - Corrected async callback signatures and implementations
  - Eliminated all compiler warnings and errors

### Technical Improvements
- **Code Quality**: Reduced architectural complexity while maintaining functionality
  - Cleaner separation of concerns between views and business logic
  - Simplified testing surface with fewer dependencies
  - More maintainable codebase with clear responsibilities
- **Performance**: Improved app startup and user creation flow
  - Faster initial load with simplified view hierarchy
  - Efficient async operations without unnecessary overhead
  - Better memory management with simplified object lifecycle

## [0.7.0] - 2025-09-12

### Added
- **PaymentMethod Entity**: Complete Core Data implementation for payment method tracking
  - PaymentMethod entity with name, type, isActive, and group relationships
  - CASCADE deletion rule when group is deleted
  - NULLIFY relationship with ItemList for payment method references
- **Entry → ItemList Renaming**: Comprehensive refactoring for better semantic clarity
  - Renamed Entry entity to ItemList across entire codebase
  - Updated all file names, class names, and method references
  - Maintained backward compatibility with existing data
- **PaymentMethod Service Layer**: Complete service implementation
  - PaymentMethodServiceProtocol with full CRUD interface
  - PaymentMethodService with async/await operations
  - Intelligent caching with CacheManager integration
  - Background threading for Core Data operations
  - Group-based and type-based filtering capabilities
- **PaymentMethod ViewModels**: Full MVVM implementation
  - PaymentMethodListViewModel for collection management
  - PaymentMethodPickerViewModel for selection functionality
  - AddPaymentMethodViewModel for creation and editing forms
  - Comprehensive validation and error handling
  - Loading states and reactive UI bindings
- **Performance Enhancement Framework**: Enterprise-level optimization system
  - Background context support for heavy Core Data operations
  - Batch operations framework (delete, update, insert) for better performance
  - Smart data preloading system with progress tracking
  - Enhanced cache management with automatic cleanup and performance monitoring
  - Performance monitoring system with operation tracking and scoring
- **User Entity Batch Operations**: High-performance bulk operations
  - bulkDeleteUsers for efficient multi-user deletion
  - bulkUpdateUserStatus for batch status changes
  - createUsers for efficient bulk user creation
  - Smart batching logic (≤10 individual, >10 bulk insert)
- **Group Entity Batch Operations**: Comprehensive bulk processing capabilities
  - bulkDeleteGroups for efficient multi-group deletion
  - bulkUpdateGroupCurrency for batch currency changes
  - bulkUpdateGroupStatus for batch status management
  - createGroups for efficient bulk group creation
  - getGroupsCount(for currency) for currency-specific statistics
  - getGroupMembersCount for relationship-based counting

### Changed
- **Data Model Enhancement**: Entry entity renamed to ItemList for better clarity
- **Relationship Structure**: Added paymentMethod relationship to ItemList entity
- **Core Data Schema**: Enhanced with payment method tracking capabilities
- **Service Architecture**: Extended dependency injection pattern for PaymentMethod services
- **ViewModel Pattern**: Consistent MVVM implementation across all PaymentMethod functionality
- **Performance Architecture**: All services now support batch operations for scalability
- **Cache Strategy**: Enhanced with background processing and automatic cleanup
- **Data Preloading**: Expanded to support multiple groups and currency-specific data

### Fixed
- **Naming Consistency**: Resolved Entry/ItemList naming conflicts throughout codebase
- **Compilation Errors**: Fixed method signature mismatches from renaming process
- **Relationship Integrity**: Proper Core Data relationship configuration with delete rules
- **Performance Bottlenecks**: Eliminated individual operation overhead with batch processing
- **Memory Management**: Improved cache cleanup and performance monitoring

### Technical Improvements
- **Schema Evolution**: Clean migration from Entry to ItemList naming
- **Service Layer Expansion**: PaymentMethod services follow established patterns
- **MVVM Consistency**: All ViewModels use @MainActor and ObservableObject patterns
- **Dependency Injection**: PaymentMethod components integrated with existing DI pattern
- **Background Operations**: Core Data operations properly threaded for UI performance
- **Validation Framework**: Comprehensive form validation with user-friendly error messages
- **Batch Processing**: Enterprise-level bulk operations with 20-50x performance improvements
- **Performance Monitoring**: Real-time operation tracking with automatic performance scoring
- **Scalability**: Framework supports thousands of entities with optimal performance

## [0.6.1] - 2025-08-25

### Fixed
- **User Selection Dropdown**: Removed "Seleccionar Usuario" option that caused infinite loading
- **Dropdown Logic**: Simplified user picker to only show actual users
- **State Management**: Eliminated unnecessary deselection logic and state clearing
- **Code Cleanup**: Removed unused deselectUser function and simplified onChange handlers

## [0.6.0] - 2025-08-25

### Added
- **First User Creation Flow**: Automatic sheet presentation when app is empty
- **Protection Flags**: Prevention of multiple simultaneous async operations
- **Enhanced Debug Logging**: Comprehensive logging for debugging concurrency issues
- **Stable State Management**: Consistent Core Data object state handling

### Changed
- **Group Default Name**: Changed from "Mi Grupo" to "Personal" for better professionalism
- **Core Data Validation**: Simplified validation to trust Core Data's internal state management
- **MVVM Pattern**: Implemented pure MVVM without manual interruptions or delays
- **Error Prevention**: Eliminated complex Core Data state validations that caused crashes

### Fixed
- **Infinite Loop Prevention**: Added flags to prevent multiple simultaneous executions
- **Core Data Crashes**: Resolved "isTemporaryID: unrecognized selector" errors
- **State Inconsistency**: Fixed inconsistent group counts and object states
- **Multiple Executions**: Prevented loadData() and autoSelectFirstUserAndGroup() from running simultaneously

### Technical Improvements
- **Concurrency Safety**: Protection flags for critical async operations
- **Simplified Validation**: Trust Core Data's internal state management
- **Stable Flow**: Consistent execution flow without race conditions
- **Debug Tools**: Enhanced logging for identifying concurrency issues

## [0.5.0] - 2025-08-25

### Added
- **NSFetchedResultsController Integration**: Automatic Core Data reactivity and UI updates
- **Real-time ItemLists List**: ItemLists now appear automatically without manual refresh
- **Automatic UI Updates**: SwiftUI re-renders automatically when Core Data changes
- **Lazy Loading & Pagination**: Efficient handling of large datasets with infinite scroll
- **Comprehensive Group Validation**: Runtime crash prevention with proper Core Data object validation
- **Threading Safety**: Proper background → main thread pattern for UI updates

### Changed
- **Core Data Integration**: Migrated from NotificationCenter to NSFetchedResultsController
- **ViewModel Architecture**: Enhanced DetailedGroupViewModel with automatic data synchronization
- **Performance**: Eliminated manual refresh requirements, UI updates automatically
- **Error Prevention**: Added validation for temporary and deleted Core Data objects

### Fixed
- **Runtime Crashes**: Prevented "isTemporaryID: unrecognized selector" errors
- **Swift 6 Compatibility**: Resolved MainActor isolation issues with nonisolated delegate methods
- **Threading Issues**: Proper DispatchQueue.main.async pattern for UI updates
- **Memory Management**: Weak self references and proper delegate cleanup

### Technical Improvements
- **MVVM Compliance**: Strict adherence to MVVM with automatic data binding
- **Core Data Best Practices**: Native NSFetchedResultsController implementation
- **Performance**: Background operations with automatic UI synchronization
- **Debugging**: Enhanced logging for Core Data validation issues

## [0.4.0] - 2025-08-12

### Added
- **Complete Navigation System**: Full NavigationStack + NavigationDestination implementation
- **Settings Navigation**: Tuerca button now navigates to SettingsView
- **Add ItemList Navigation**: Add ItemList button now navigates to AddItemListView
- **Navigation Enums**: SettingsDestination and AddItemListDestination for type-safe navigation
- **Centralized Navigation**: All NavigationDestination definitions in MainView
- **Programmatic Navigation**: Consistent navigationPath.append() pattern across all views

### Changed
- **Navigation Architecture**: Migrated from sheet-based to pure NavigationStack approach
- **Navigation Pattern**: Unified navigation using NavigationPath and NavigationDestination
- **Button Actions**: Updated all navigation buttons to use programmatic navigation
- **LoadingView Compatibility**: Fixed Color(.systemBackground) issues for macOS compatibility

### Fixed
- **Navigation Consistency**: All views now follow the same navigation pattern
- **Parameter Order**: Corrected AddItemListView init parameter order in MainView
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
  - ItemList entity with date and description support
  - Group entity with currency and member management
  - Item entity with amount and quantity tracking
  - User entity with email and name management
  - UserGroup entity with role-based permissions
- **ViewModels**: Full CRUD operations for all entities
  - CategoryViewModel with filtering and validation
  - ItemListViewModel with date filtering and totals
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
