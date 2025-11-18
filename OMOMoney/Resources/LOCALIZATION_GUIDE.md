# 🌍 Localization Setup

## Overview

The OMOMoney app now supports multiple languages with a clean, organized localization structure.

## Structure

```
OMOMoney/Resources/
├── en.lproj/
│   └── Localizable.strings    (English)
└── es.lproj/
    └── Localizable.strings    (Spanish)
```

## Supported Languages

- ✅ **English (en)** - Default language
- ✅ **Spanish (es)** - Segunda idioma

## How to Use

### 1. Using String Extension (Recommended)

```swift
// Simple localization
let title = "user.title".localized
let message = LocalizationKey.User.title.localized

// With format arguments
let count = 5
let message = "user.count".localized(with: count)
```

### 2. Using SwiftUI Text (Direct)

```swift
import SwiftUI

struct UserView: View {
    var body: some View {
        VStack {
            // Using localization key directly
            Text("user.title", bundle: .main)
            
            // Or using the enum
            Text(LocalizationKey.User.title.localized)
            
            // Or using extension
            Text("user.create".localized)
        }
    }
}
```

### 3. Using LocalizationKey Enum (Type-Safe)

```swift
// Type-safe approach - prevents typos
let title = LocalizationKey.User.title.localized
let createButton = LocalizationKey.User.create.localized
let deleteConfirm = LocalizationKey.User.deleteConfirm.localized
```

## Available Key Categories

### General Keys
- `general.ok`, `general.cancel`, `general.save`, `general.delete`, etc.

### Navigation Keys
- `nav.dashboard`, `nav.groups`, `nav.categories`, etc.

### Feature-Specific Keys
- **User:** `user.title`, `user.name`, `user.email`, etc.
- **Group:** `group.title`, `group.name`, `group.currency`, etc.
- **Category:** `category.title`, `category.name`, `category.color`, etc.
- **Entry:** `entry.title`, `entry.description`, `entry.amount`, etc.
- **Payment:** `payment.title`, `payment.name`, `payment.type`, etc.
- **Dashboard:** `dashboard.title`, `dashboard.totalExpenses`, etc.
- **Settings:** `settings.title`, `settings.language`, etc.

### Error Messages
- **Validation:** `error.validation.emptyName`, `error.validation.invalidEmail`, etc.
- **Repository:** `error.repository.notFound`, `error.repository.saveFailed`, etc.

### Success Messages
- `success.created`, `success.updated`, `success.deleted`, etc.

## Adding a New Language

1. **Create new language directory:**
   ```bash
   mkdir -p OMOMoney/Resources/pt.lproj  # Portuguese example
   ```

2. **Copy English strings file:**
   ```bash
   cp OMOMoney/Resources/en.lproj/Localizable.strings \
      OMOMoney/Resources/pt.lproj/Localizable.strings
   ```

3. **Translate the strings** in the new file

4. **Add to Xcode project** (if needed)

## Adding New Localization Keys

### 1. Add to both `.strings` files

**en.lproj/Localizable.strings:**
```strings
"feature.newKey" = "New Feature Text";
```

**es.lproj/Localizable.strings:**
```strings
"feature.newKey" = "Nuevo Texto de Característica";
```

### 2. Add to LocalizationKey enum

**String+Localization.swift:**
```swift
enum LocalizationKey {
    enum Feature {
        static let newKey = "feature.newKey"
    }
}
```

### 3. Use in your code

```swift
Text(LocalizationKey.Feature.newKey.localized)
// or
Text("feature.newKey".localized)
```

## Best Practices

### ✅ DO

- Use `LocalizationKey` enum for type safety
- Organize keys by feature/module
- Use descriptive key names (e.g., `user.delete.confirm`)
- Keep translations up to date in all languages
- Test with different languages enabled

### ❌ DON'T

- Hard-code user-facing strings
- Use translation text as the key
- Mix languages in the same file
- Forget to translate all keys

## Testing Different Languages

### In Simulator/Device

1. Open **Settings** app
2. Go to **General** → **Language & Region**
3. Change **iPhone Language** to Spanish (or desired language)
4. Restart the app

### In Xcode

1. **Edit Scheme** → **Run**
2. **Options** tab
3. Set **App Language** to Spanish
4. Run the app

### Programmatically (for testing)

```swift
// In AppDelegate or App init (for testing only)
UserDefaults.standard.set(["es"], forKey: "AppleLanguages")
```

## File Encoding

All `.strings` files use **UTF-8** encoding to support special characters in all languages.

## Future Language Support

Planned languages to add:
- [ ] Portuguese (pt)
- [ ] French (fr)
- [ ] German (de)
- [ ] Italian (it)
- [ ] Chinese (zh-Hans)
- [ ] Japanese (ja)

## Tools

### GenStrings (extract strings from code)

```bash
find . -name "*.swift" | xargs genstrings -o Resources/en.lproj/
```

### Validate Strings Files

```bash
plutil -lint Resources/en.lproj/Localizable.strings
plutil -lint Resources/es.lproj/Localizable.strings
```

---

**Setup Date:** November 18, 2025  
**Default Language:** English (en)  
**Status:** ✅ Ready to use
