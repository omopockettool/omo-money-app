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

## ✨ Features

### ✅ Completed
- **User Management**: Create, read, update, delete users
- **Core Data Integration**: Full persistence layer
- **MVVM Architecture**: Clean separation of concerns
- **Native Performance**: Background operations for smooth UI
- **Modern Navigation**: NavigationStack + NavigationDestination implementation
- **Complete Navigation System**: Settings, Create Group, Add Entry all working
- **Error Handling**: Comprehensive user feedback

### 🚧 In Development
- **Group Management**: Create and manage expense groups
- **User-Group Relationships**: Role-based permissions
- **Category Management**: Expense categorization
- **Entry Management**: Expense tracking
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
- **Entry**: Main expense records
- **Item**: Individual expense items
- **UserGroup**: User-group relationships with roles

### Performance Features
- **Background Queues**: Core Data operations don't block UI
- **@MainActor**: UI thread safety for all ViewModels
- **Efficient Filtering**: Optimized data queries
- **Memory Management**: Proper Core Data context handling

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
└── ContentView.swift       # App entry point
```

## 🔧 Development Workflow

### Phase-Based Development
1. **Phase 1** ✅: Core Data foundation and ViewModels
2. **Phase 2** 🚧: Basic UI implementation
3. **Phase 3**: Business logic and calculations
4. **Phase 4**: Advanced features and analytics
5. **Phase 5**: Polish and testing

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

**Last Updated**: December 19, 2024  
**Current Version**: 0.2.0  
**Development Phase**: Phase 2 - Basic UI Structure
