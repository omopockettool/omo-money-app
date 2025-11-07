# OMOMoney - SwiftUI Expense Tracker App

A native iOS personal expense tracker app built with SwiftUI, following strict MVVM architecture and Core Data persistence.

## 🚀 Current Status

**Phase 1: Core Data Foundation** ✅ **COMPLETED**
- All Core Data entities implemented
- Complete ViewModels with CRUD operations
- Native performance optimizations
- Background queue implementation

**Phase 2: Basic UI Structure** ✅ **COMPLETED**
- User management UI completed
- NavigationStack implementation
- Create Group from User functionality implemented
- Complete navigation system with NavigationStack + NavigationDestination

**Phase 2.5: Architecture & Stability** ✅ **COMPLETED**
- First user creation flow with automatic sheet presentation
- Protection flags to prevent multiple simultaneous operations
- Stable Core Data state management
- Simplified validation trusting Core Data's internal state
- Infinite loop prevention and concurrency safety

**Phase 3: Dashboard & Swipe-to-Delete** ✅ **COMPLETED**
- Dashboard with expense list view
- Native iOS swipe-to-delete pattern (List with swipeActions)
- Incremental cache pattern (Apple-style)
- Core Data NSManagedObjectContextDidSave notifications
- Optimized performance (0% CPU, 35.3MB with 1420+ records)
- NaN protection in calculations (3-level isFinite checks)
- @Published cached properties instead of computed

## ✨ Features

### ✅ Completed
- **User Management**: Create, read, update, delete users
- **Core Data Integration**: Full persistence layer
- **MVVM Architecture**: Clean separation of concerns
- **Native Performance**: Background operations for smooth UI
- **Modern Navigation**: NavigationStack + NavigationDestination implementation
- **Complete Navigation System**: Settings, Create Group, Add ItemList all working
- **Error Handling**: Comprehensive user feedback
- **First User Flow**: Automatic user creation when app is empty
- **Stability Features**: Protection against multiple operations and infinite loops
- **Core Data Safety**: Simplified validation trusting Core Data's internal state
- **PaymentMethod Management**: Complete CRUD operations for payment methods
- **Entry → ItemList Refactoring**: Semantic clarity improvements with comprehensive renaming
- **Dashboard UI**: Display expense lists grouped by date
- **Swipe-to-Delete**: Native iOS pattern for deleting ItemLists
- **Quick Expense Creation**: Modal for fast expense tracking
- **Incremental Cache**: Apple-style cache updates without DB queries
- **Real-time Sync**: Core Data notifications for auto-updates
- **Performance Optimized**: 0% CPU, handles 1000+ records smoothly
- **NaN Protection**: 3-level validation in calculations

### 🚧 In Development
- **Group Management**: Create and manage expense groups
- **User-Group Relationships**: Role-based permissions
- **Category Management**: Expense categorization
- **Item Management**: Individual expense items

### 📋 Planned
- **Expense Analytics**: Charts and reports
- **Multi-Currency Support**: International expense tracking
- **Data Export**: Backup and sharing functionality
- **Notifications**: Reminders and alerts

## 🏗️ Architecture

### MVVM Pattern
- **Models**: Core Data entities with proper relationships
- **ViewModels**: Business logic and data management
- **Views**: Pure UI components with no business logic

### Core Data Entities
- **User**: App users with authentication
- **Group**: Expense groups for sharing
- **Category**: Expense categorization
- **ItemList**: Main expense item lists with dates and descriptions
- **Item**: Individual expense items within item lists
- **PaymentMethod**: Payment method tracking for groups (credit cards, cash, etc.)
- **UserGroup**: User-group relationships with roles

### Performance Features
- **Background Queues**: Core Data operations don't block UI
- **@MainActor**: UI thread safety for all ViewModels
- **Efficient Filtering**: Optimized data queries
- **Memory Management**: Proper Core Data context handling
- **NSFetchedResultsController**: Automatic Core Data reactivity and UI updates
- **Lazy Loading**: Efficient pagination for large datasets
- **Real-time Updates**: ItemLists list updates automatically without manual refresh
- **Concurrency Safety**: Protection flags prevent multiple simultaneous operations
- **Stable State Management**: Consistent Core Data object states
- **Infinite Loop Prevention**: Robust protection against recursive operations
- **Incremental Cache Pattern**: Updates in-memory arrays instead of invalidating cache
- **Core Data Notifications**: NSManagedObjectContextDidSave for auto-sync
- **Optimized Computed Properties**: @Published cached vars instead of recomputing
- **NaN Protection**: isFinite validation at item, itemList, and total levels
- **Duplicate Prevention**: ObjectID checks in Core Data observers

## 🛠️ Technical Requirements

- **iOS**: 16.0+
- **Swift**: 5.9+
- **Xcode**: 16.0+
- **Architecture**: MVVM with Core Data
- **Navigation**: NavigationStack (iOS 16+)

## 📱 Screenshots

*Coming soon - App is currently in development*

## 🚀 Getting Started

### Prerequisites
- Xcode 16.0 or later
- iOS 16.0+ device or simulator
- Basic knowledge of SwiftUI and Core Data

### Installation
1. Clone the repository
2. Open `OMOMoney.xcodeproj` in Xcode
3. Select your target device
4. Build and run the project

### Development Setup
1. Ensure all Core Data entities are properly configured
2. Verify ViewModels follow MVVM pattern
3. Test on physical device for best performance validation

## 📁 Project Structure

```
OMOMoney/
├── View/                    # SwiftUI Views
│   ├── MainView.swift      # Root navigation
│   ├── UserListView.swift  # User list display
│   ├── AddUserView.swift   # User creation form
│   └── EditUserView.swift  # User editing form
├── ViewModel/              # MVVM ViewModels
│   ├── UserViewModel.swift # User business logic
│   ├── GroupViewModel.swift # Group business logic
│   └── ...                 # Other entity ViewModels
├── OMOMoney.xcdatamodeld/  # Core Data model
├── Persistence.swift       # Core Data stack
└── ContentView.swift       # App itemList point
```

## 🔧 Development Workflow

### Phase-Based Development
1. **Phase 1** ✅: Core Data foundation and ViewModels
2. **Phase 2** ✅: Basic UI implementation and navigation system
3. **Phase 2.5** ✅: Architecture stability and first user flow
4. **Phase 3** 🚧: Business logic, calculations, and real-time data updates
5. **Phase 4**: Advanced features and analytics
6. **Phase 5**: Polish and testing

### Commit Strategy
- Small, focused commits for each feature
- Clear commit messages following conventional commits
- Test on physical device before each commit
- Maintain clean git history

## 🧪 Testing

### Current Testing
- **Physical Device Testing**: Primary testing method
- **Core Data Validation**: Entity relationships and CRUD operations
- **UI Responsiveness**: Performance and user experience

### Planned Testing
- **Unit Tests**: ViewModel logic validation
- **UI Tests**: User interaction flows
- **Performance Tests**: Core Data operation timing
- **Integration Tests**: End-to-end workflows

## 🤝 Contributing

This is a personal development project. The architecture and patterns are designed for learning and demonstration purposes.

### Development Guidelines
- Follow MVVM architecture strictly
- Keep Views free of business logic
- Use background queues for heavy operations
- Maintain native iOS performance standards
- Test on physical devices regularly

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Roadmap

### Short Term (Next 2 weeks)
- Complete Group management UI
- Implement User-Group relationship management
- Add Category management interface

### Medium Term (Next month)
- Complete all entity UI implementations
- Add expense calculation logic
- Implement basic analytics

### Long Term (Next quarter)
- Advanced features and polish
- Performance optimization
- App Store preparation

## 📞 Support

For development questions or issues:
- Review the [TODO.md](TODO.md) for current development status
- Check [CHANGELOG.md](CHANGELOG.md) for recent changes
- Ensure you're testing on a physical device

---

**Last Updated**: November 7, 2025  
**Current Version**: 0.12.0  
**Development Phase**: Phase 3 - Dashboard & Swipe-to-Delete (COMPLETED)

