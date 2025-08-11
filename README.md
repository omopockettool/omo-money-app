# OMOMoney

A native iOS personal expense tracker app built with SwiftUI and Core Data, following strict MVVM architecture principles.

## Features

- **Expense Tracking**: Log and categorize your daily expenses
- **Group Management**: Share expenses with family or roommates
- **Category Management**: Organize expenses with custom categories
- **Multi-Currency Support**: Handle different currencies for international users
- **User Roles**: Different permission levels for group members
- **Core Data Persistence**: Reliable local data storage

## Requirements

- iOS 16.0+
- Xcode 16.0+
- Swift 5.0+
- macOS 15.5+ (for development)

## Architecture

This app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

- **Model**: Core Data entities (Category, Entry, Group, Item, User, UserGroup)
- **View**: SwiftUI views that display data and handle user interactions
- **ViewModel**: ObservableObject classes that manage business logic and Core Data operations

## Project Structure

```
OMOMoney/
├── Model/           # Core Data entities
├── ViewModel/       # MVVM ViewModels
├── View/            # SwiftUI views
├── Persistence/     # Core Data stack
└── Assets/          # App resources
```

## Core Data Model

The app uses the following entities:

- **Category**: Expense categories with color coding
- **Entry**: Main expense entries with dates and descriptions
- **Group**: Expense groups for sharing between users
- **Item**: Individual items within an expense entry
- **User**: App users with authentication
- **UserGroup**: Junction table for user-group relationships

## Getting Started

1. Clone the repository
2. Open `OMOMoney.xcodeproj` in Xcode
3. Select your target device (physical device recommended)
4. Build and run the project

## Development

This project follows incremental development principles:

- Small, focused commits for each feature
- Test-driven development approach
- MVVM architecture compliance
- Performance optimization for Core Data operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following MVVM principles
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Dennis Chicaiza A

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version information.
