# 📚 OMOMoney Documentation

Complete documentation for the OMOMoney iOS expense tracker app with Clean Architecture.

---

## ⚡ **NEW SESSION? START HERE!**

### 🎯 Quick Start Files (Read These)

1. **[START_HERE.md](START_HERE.md)** ⭐ **ALWAYS READ THIS FIRST**
   - Critical architecture rules (~2,000 tokens)
   - Layer boundaries, DI patterns, red flags
   - **Use this to start EVERY session**

2. **[SESSION_PROMPTS.md](SESSION_PROMPTS.md)** 📋 **COPY-PASTE TEMPLATES**
   - Ready-to-use prompts for common scenarios
   - Token cost comparisons
   - Session workflow guide

3. **[QUICK_REFERENCE_CARD.md](QUICK_REFERENCE_CARD.md)** 🎯 **CHEAT SHEET**
   - One-page reference for development
   - Do's and don'ts
   - Quick architecture checks
   - **Print this or keep it visible**

4. **[OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md)** 📊 **HOW THIS WORKS**
   - Why we optimized the docs
   - Token savings breakdown (87% reduction!)
   - Before/after comparison

---

## 🤖 Optimal Session Start Prompt

**Copy-paste this into Claude Sonnet 4.5**:
```
Read docs/START_HERE.md to load OMOMoney architecture context.
Then help me with: [your specific task]
```

**Result**:
- ✅ Critical architecture rules loaded
- ✅ ~2,000 tokens (vs 15,000 for all docs)
- ✅ 87% token savings
- ✅ Ready to develop in ~5 seconds

---

## 🤖 MCP Skills Configuration

For AI assistants supporting Model Context Protocol (MCP):

Use the skills defined in `/.mcp/skills.json`:

1. **`omo-ios-architecture`** - Load architecture context (default)
2. **`omo-new-feature`** - Add feature following Clean Architecture
3. **`omo-debug-architecture`** - Debug layer violations
4. **`omo-view-structure`** - View project organization

**Entry point**: All skills start with `docs/START_HERE.md`
- ✅ Layer boundaries understood
- ✅ DI patterns ready
- ✅ Minimal token cost (~2K vs 15K)

---

## 🏗️ Architecture Documentation

**Essential reading** (load only when needed):

### Quick References
- **[START_HERE.md](START_HERE.md)** ⭐ **READ THIS FIRST**
  - Condensed architecture rules
  - Critical patterns and anti-patterns
  - Quick file location guide

- **[RULES.md](RULES.md)** - Strict architecture rules
  - Clean Architecture boundaries (MANDATORY)
  - Auto-reject patterns
  - Current compliance status

- **[QUICK_START.md](architecture/QUICK_START.md)** - Fast layer overview
  - Layer responsibilities summary
  - Common patterns cheat sheet
  - Where to put new files

### Detailed Guides
- **[CLEAN_ARCHITECTURE_GUIDE.md](architecture/CLEAN_ARCHITECTURE_GUIDE.md)** - Complete explanation
  - Layer responsibilities and boundaries
  - Code examples and patterns
  - Best practices and anti-patterns
  - Testing strategies

- **[ARCHITECTURE_DIAGRAMS.md](architecture/ARCHITECTURE_DIAGRAMS.md)** - Visual diagrams
  - High-level architecture overview
  - Dependency flow diagrams
  - Data flow examples
  - File organization tree

- **[PROJECT_STRUCTURE.md](architecture/PROJECT_STRUCTURE.md)** - Detailed structure
  - Complete directory layout
  - File organization by layer
  - Naming conventions
  - Quick reference tables

### Historical Context
- **[CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md](CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md)** - What was fixed
  - Complete refactor history (Dec 2025)
  - Before/after examples
  - 26 violations → 0 violations
  - Refactoring patterns used

---

## 🎓 Learning Path

### For New Developers
1. **[START_HERE.md](START_HERE.md)** ← Start here (3 min)
2. **[QUICK_START.md](architecture/QUICK_START.md)** ← Layer overview (5 min)
3. **[CLEAN_ARCHITECTURE_GUIDE.md](architecture/CLEAN_ARCHITECTURE_GUIDE.md)** ← Deep dive (20 min)
4. **[PROJECT_STRUCTURE.md](architecture/PROJECT_STRUCTURE.md)** ← File organization (10 min)

### For AI Assistants
**Optimal session start**:
```
Read docs/START_HERE.md, then help me with [task]
```

**Token cost comparison**:
- START_HERE.md only: ~2,000 tokens ✅
- All architecture docs: ~15,000 tokens ❌
- On-demand loading: Load specific docs as needed ✅

---

## � Getting Started

### 💡 Starting a New AI Session?

**Use this prompt**:
```
Read docs/START_HERE.md to load OMOMoney architecture context.
Then help me [describe your task].
```

### 👨‍💻 New Developer on the Project?

1. **Read**: [START_HERE.md](START_HERE.md) (3 min) - Get the essentials
2. **Explore**: [QUICK_START.md](architecture/QUICK_START.md) (5 min) - Understand layers
3. **Deep dive**: [CLEAN_ARCHITECTURE_GUIDE.md](architecture/CLEAN_ARCHITECTURE_GUIDE.md) (20 min)
4. **Reference**: [PROJECT_STRUCTURE.md](architecture/PROJECT_STRUCTURE.md) (10 min)

### ✨ Adding a New Feature?

1. Read [START_HERE.md](START_HERE.md) - "Adding New Feature" section
2. Follow the 7-step pattern (Domain → UseCase → Repository → DI → ViewModel → View)
3. Verify: No `import CoreData` in Presentation layer
4. Test at each layer independently

### 🐛 Debugging Architecture Issues?

1. Read [RULES.md](RULES.md) - Check violation rules
2. Review [CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md](CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md) - See fix examples
3. Use grep to find violations:
   - `import CoreData` in `Presentation/`
   - `NSManagedObjectContext` in ViewModels
   - Direct Service/Repository instantiation

### 🔄 Need to Refactor?

1. Review [CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md](CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md)
2. Follow established patterns from the summary
3. Test after each change
4. Verify compliance with [RULES.md](RULES.md)

---

## 🗂️ Documentation Structure

```
docs/
├── START_HERE.md ⭐                   # Quick start (READ THIS FIRST!)
├── README.md                          # This file
├── RULES.md                           # Architecture rules (MANDATORY)
├── CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md  # What was fixed
│
├── architecture/                      # Architecture deep dives
│   ├── QUICK_START.md                # Fast layer overview
│   ├── CLEAN_ARCHITECTURE_GUIDE.md   # Complete guide
│   ├── ARCHITECTURE_DIAGRAMS.md      # Visual diagrams
│   └── PROJECT_STRUCTURE.md          # File organization
│
├── guides/                            # How-to guides
│   ├── IMPLEMENTATION_GUIDE.md       # Reorganization guide
│   ├── PROJECT_REORGANIZATION_PLAN.md# Migration plan
│   └── LOCALIZATION_SETUP.md         # Localization setup
│
└── archived/                          # Historical docs
    └── ...                            # Completed/superseded docs
```

---

## �📖 Implementation Guides

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
