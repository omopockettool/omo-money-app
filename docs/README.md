# 📚 OMOMoney Documentation

Complete documentation for the OMOMoney iOS expense tracker app.

---

## 🏗️ Architecture Documentation

Essential reading for understanding the project structure:

- **[CLEAN_ARCHITECTURE_GUIDE.md](architecture/CLEAN_ARCHITECTURE_GUIDE.md)** - Complete Clean Architecture explanation
  - Layer responsibilities and boundaries
  - Code examples and patterns
  - Best practices and anti-patterns
  - Testing strategies

- **[ARCHITECTURE_DIAGRAMS.md](architecture/ARCHITECTURE_DIAGRAMS.md)** - Visual architecture diagrams
  - High-level architecture overview
  - Dependency flow diagrams
  - Data flow examples
  - File organization tree

- **[PROJECT_STRUCTURE.md](architecture/PROJECT_STRUCTURE.md)** - Detailed project structure
  - Complete directory layout
  - File organization by layer
  - Naming conventions
  - Quick reference tables

- **[QUICK_START.md](architecture/QUICK_START.md)** - Quick reference guide
  - Fast overview for new developers
  - Layer summary
  - Common patterns
  - Where to put new files

---

## 📖 Implementation Guides

Step-by-step guides for specific tasks:

- **[IMPLEMENTATION_GUIDE.md](guides/IMPLEMENTATION_GUIDE.md)** - Project reorganization guide
  - Phase-by-phase reorganization steps
  - Troubleshooting tips
  - Testing checkpoints
  - Time estimates (~4 hours)

- **[PROJECT_REORGANIZATION_PLAN.md](guides/PROJECT_REORGANIZATION_PLAN.md)** - Migration plan
  - Detailed reorganization strategy
  - File movement tracking
  - Benefits and rationale
  - Implementation priority

- **[LOCALIZATION_SETUP.md](guides/LOCALIZATION_SETUP.md)** - Localization guide
  - Multi-language support setup
  - String externalization
  - Language file management
  - Best practices

---

## 📦 Archived Documentation

Historical documentation for reference (completed or superseded):

- **[ARCHITECTURE_IMPROVEMENT_TODO.md](archived/ARCHITECTURE_IMPROVEMENT_TODO.md)** - Old architecture improvement plan
- **[CLEAN_ARCHITECTURE_IMPLEMENTATION.md](archived/CLEAN_ARCHITECTURE_IMPLEMENTATION.md)** - Original implementation notes
- **[IMPLEMENTATION_COMPLETE_SUMMARY.md](archived/IMPLEMENTATION_COMPLETE_SUMMARY.md)** - Implementation summary
- **[REORGANIZATION_CHECKLIST.md](archived/REORGANIZATION_CHECKLIST.md)** - Completed reorganization checklist
- **[VIEWMODEL_MIGRATION_GUIDE.md](archived/VIEWMODEL_MIGRATION_GUIDE.md)** - Old ViewModel migration guide

---

## 🗂️ Documentation Structure

```
docs/
├── README.md                          # This file
├── architecture/                      # Architecture documentation
│   ├── CLEAN_ARCHITECTURE_GUIDE.md   # Complete guide
│   ├── ARCHITECTURE_DIAGRAMS.md      # Visual diagrams
│   ├── PROJECT_STRUCTURE.md          # File organization
│   └── QUICK_START.md                # Quick reference
├── guides/                            # How-to guides
│   ├── IMPLEMENTATION_GUIDE.md       # Reorganization guide
│   ├── PROJECT_REORGANIZATION_PLAN.md# Migration plan
│   └── LOCALIZATION_SETUP.md         # Localization setup
└── archived/                          # Historical docs
    └── ...                            # Completed/superseded docs
```

---

## 🚀 Getting Started

### New to the Project?

1. **Start here**: [QUICK_START.md](architecture/QUICK_START.md)
2. **Understand architecture**: [CLEAN_ARCHITECTURE_GUIDE.md](architecture/CLEAN_ARCHITECTURE_GUIDE.md)
3. **Explore structure**: [PROJECT_STRUCTURE.md](architecture/PROJECT_STRUCTURE.md)
4. **See diagrams**: [ARCHITECTURE_DIAGRAMS.md](architecture/ARCHITECTURE_DIAGRAMS.md)

### Adding a New Feature?

1. Review the [CLEAN_ARCHITECTURE_GUIDE.md](architecture/CLEAN_ARCHITECTURE_GUIDE.md) - Layer responsibilities
2. Check [PROJECT_STRUCTURE.md](architecture/PROJECT_STRUCTURE.md) - Where to put files
3. Follow the established patterns in each layer
4. Test at each layer independently

### Need to Refactor?

1. Review [IMPLEMENTATION_GUIDE.md](guides/IMPLEMENTATION_GUIDE.md) for reorganization patterns
2. Follow the phase-by-phase approach
3. Test after each phase
4. Document your changes

---

## 📝 Contributing to Documentation

When updating documentation:

1. **Architecture docs** → Place in `docs/architecture/`
2. **How-to guides** → Place in `docs/guides/`
3. **Outdated docs** → Move to `docs/archived/`
4. **Update this README** to include new documentation

---

## 🔗 Related Files

- [README.md](../README.md) - Main project README
- [CHANGELOG.md](../CHANGELOG.md) - Project changelog
- [TODO.md](../TODO.md) - Development task list

---

**Last Updated**: November 27, 2025
**Version**: 1.0.0
