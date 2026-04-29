You are implementing a high-performance, low-friction “concept input system” for an iOS app built with Swift + UIKit.

## 🎯 Goal
Enable the fastest possible entry creation (< 3 seconds) by:
- Minimizing typing
- Reducing decision-making
- Providing intelligent suggestions without clutter

The concept field must feel optional, assisted, and frictionless.

---

## 🧠 Core UX Principles

- Concept input is OPTIONAL
- Typing must ALWAYS be immediately available (never hidden)
- Suggestions are assistive, never blocking
- Zero additional taps required to start typing
- Max 3 suggestions at any time
- UI must stay visually clean

---

## 📱 UI Structure

### Always visible:

1. Amount input (primary)
2. Concept text field (secondary, optional)
3. Category selector

### Conditional:

- Suggestion chips appear ONLY when the concept field is focused

---

## ✏️ Concept Input Behavior

### Default (no interaction)
- Concept field is visible
- Placeholder shows last used concept (light gray hint)
  Example:
  "Ahorramas"

- No chips visible

---

### On Focus (user taps concept field)

IF user has history:
→ Show up to 3 suggestion chips BELOW the text field

Suggestions:
- Based on most recent concepts
- Prefer concepts from current category

Example:
[ Ahorramas ] [ Café ] [ Gasolina ]

IF no history:
→ Show nothing

---

### On Typing

As user types:
- Dynamically filter suggestions
- Show max 3 results

Matching priority:
1. Prefix match (starts with)
2. Contains match
3. Recency (lastUsedDate)
4. Frequency (usageCount)

Case insensitive

---

### On Chip Tap

- Fill text field with selected concept
- Keep keyboard open
- Cursor at end
- Allow immediate save

---

### Autofill (Silent Assist)

When:
- User enters amount
- AND does NOT type in concept

THEN:
- Auto-suggest last used concept for that category
- Show as subtle placeholder (NOT committed text)

Example:
User selects "Alimentación"
→ Placeholder becomes: "Ahorramas"

If user saves:
→ This value is used as concept

If user types:
→ Placeholder is replaced

---

## 🗃️ Data Model

Each entry list in OMOMoney/Data/SwiftData/SDItemList.swift
Maintain a lightweight concept store:

ConceptStats:
- name: String
- lastUsedDate: Date
- usageCount: Int
- category: String

---

## 🔍 Suggestion Engine

Function:

getSuggestions(query: String?, category: String) -> [String]

Rules:

IF query is empty:
→ Return last 3 used concepts (prioritize current category)

IF query exists:
→ Return top 3 sorted by:
    - prefix match
    - contains match
    - recency
    - frequency

Always deduplicate
Always limit to 3

---

## 🎨 UI Component (Chips)

- Horizontal scroll (if needed)
- Max 3 visible
- Rounded pill style
- Minimal contrast (not visually dominant)
- Smooth fade/slide animation on appearance
- Positioned directly below text field

---

## ⚡ Performance

- Suggestions must be instant
- Use in-memory caching
- Avoid blocking main thread
- Preload recent concepts

---

## 🚫 What NOT to do

- Do NOT hide the text input behind buttons
- Do NOT require selecting a chip
- Do NOT show suggestions before interaction
- Do NOT show more than 3 suggestions
- Do NOT clutter UI with too many elements

---

## 🧪 Edge Cases

- No history → no chips
- Long concepts → truncate visually
- Duplicate entries → merge stats
- Empty concept → fallback to category name

---

## ✅ Expected User Flow

1. User opens form
2. Types amount (e.g. 5€)
3. (Optional) taps concept field
4. Sees suggestions OR ignores
5. Saves instantly

OR

1. Types amount
2. Saves immediately
→ system auto-fills concept from category history

---

## 🎯 Success Criteria

- Entry time under 3 seconds
- Reduced typing frequency
- High daily usage
- No perceived friction

---

Build this modularly and cleanly, with separation between:
- UI layer
- suggestion engine
- data storage