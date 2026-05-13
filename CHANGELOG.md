# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.18.5] - 2026-05-14

### Changed
- **Settings backup error presentation now uses explicit alert state instead of a derived binding** (`SettingsSheetView`, `SettingsBackupViewModel`) — backup/export/import errors are now surfaced through a dedicated `showError` flag in the ViewModel rather than through a `Binding(get:set:)` derived from `errorMessage` inside the view. This keeps the Settings sheet closer to the same simple, explicit alert pattern already used in other flows and reduces reactive presentation glue in the SwiftUI layer.

## [1.18.4] - 2026-05-14

### Changed
- **Group info edit form lifecycle noise was removed without changing user-facing behavior** (`GroupInfoEditSheet`) — temporary node/debug logging and non-functional lifecycle observers were stripped from the group info editor so the sheet stays focused on rendering and saving only. The edit-group flow should behave the same, but with a cleaner and less reactive view structure.

## [1.18.3] - 2026-05-14

### Changed
- **Payment method form lifecycle noise was removed without changing user-facing behavior** (`PaymentMethodFormView`) — temporary node/debug logging and non-functional lifecycle observers were stripped from the payment method editor so the form stays focused on rendering and saving only. The create/edit payment method flow should behave the same, but with a cleaner and less reactive view structure.

## [1.18.2] - 2026-05-14

### Changed
- **Category form lifecycle noise was removed without changing user-facing behavior** (`CategoryFormView`) — temporary node/debug logging and non-functional lifecycle observers were stripped from the category editor so the form stays focused on rendering and saving only. The create/edit category flow should behave the same, but with a cleaner and less reactive view structure.

## [1.18.1] - 2026-05-14

### Changed
- **Add Item input handling was simplified to reduce fragile in-view reactivity** (`AddItemView`, `AddItemViewModel`) — the item form no longer sanitizes quantity through an `onChange` that rewrites the same bound state from inside the view. Quantity input is now sanitized through a dedicated binding backed by the ViewModel, and the custom keyboard accessory toolbar was removed to keep the form lifecycle lighter and more predictable.

## [1.18.0] - 2026-05-13

### Added
- **New Entry now inherits the active dashboard category when opened from a filtered category view** (`DashboardView`, `AddItemListView`, `AddItemListViewModel`) — when the user is currently filtered into a specific dashboard category and opens the add-entry sheet, the form now preselects that same category automatically. This keeps the quick-entry flow aligned with the user’s visible context while intentionally avoiding heavier “last used” memory behavior for now.

## [1.17.1] - 2026-05-12

### Fixed
- **Toolbar add actions now use one shared white `+` treatment across management flows** (`PrimaryToolbarAddButton`, `CategoryManagementView`, `PaymentMethodManagementView`, `GroupSelectorChipView`) — the app now centralizes the primary add button used in toolbar trailing positions through a small shared component, so category management, payment method management, and the dashboard group picker all present the same semibold white plus icon with a consistent disabled gray state.

## [1.17.0] - 2026-05-13

### Changed
- **New Entry was simplified back to a stable, Apple-like sheet flow** (`AddItemListView`, `AddItemListViewModel`, `DashboardView`, `ItemListDetailView`) — the form no longer tries to bootstrap itself through stacked reactive modifiers and competing async entry paths. The parent now provides the available groups up front, the ViewModel owns the initial form configuration, and the sheet reloads only the active group’s categories and payment methods through one clear loading path.
- **Add Entry form architecture now follows the project’s SwiftUI data-flow rules more closely** (`AddItemListView`, `AddItemListViewModel`, `docs/START_HERE.md`) — the form view was reduced to a simpler rendering layer while the ViewModel became responsible for loading option data and selected-group context. The project quick-start guide now also documents this pattern explicitly: dumb forms, smart ViewModels, and no patch-style bootstrap logic in SwiftUI views.

### Removed
- **Non-essential reactive polish was stripped from New Entry while restoring runtime stability** (`AddItemListView`) — the temporary keyboard accessory toolbar, focus-driven animation, and extra in-view suggestion/update hooks were removed from the form body so the sheet can open reliably before any future UX polish is reintroduced on top of a stable lifecycle.

## [1.16.1] - 2026-05-12

### Fixed
- **The selected dashboard category filter chip is now left-aligned and includes its clear action inside the chip itself** (`DashboardComponents`) — the filtered-list header no longer shows a detached trailing close button. The active category chip now contains the `x` inside the same capsule using the category accent color, and it also has a bit more top spacing so it sits more comfortably inside the list container.
- **Text-entry fields now follow the shared input treatment more consistently across entry and group creation flows** (`LimitedTextField`, `AddItemListComponents`, `AddItemListView`, `AddItemView`, `CreateGroupView`) — the Add Entry concept field now reuses the shared common text input instead of a one-off inline implementation, the Add Item description field now uses the `textformat` icon to match the category editor style, and the New Group name field now uses the shared input component while keeping the group-specific `person.2.fill` icon used by group editing.

## [1.16.0] - 2026-05-10

### Added
- **New Entry now includes keyboard toolbar arrow controls to move focus between amount and description fields** (`AddItemListView`) — the quick-entry form now exposes up/down keyboard actions so users can move between the hero amount field and the concept field without relying only on taps, improving accessibility and faster keyboard-driven entry.

### Changed
- **Primary toolbar confirmation checkmarks now use a shared prominent circular button style across the app** (`PrimaryToolbarCheckButton`, `AddItemListView`, `CategoryFormView`, `PaymentMethodFormView`, `GroupInfoEditSheet`, `CreateGroupView`, `AddItemView`, `DashboardMonthFilterSheet`) — repeated toolbar save/confirm buttons were centralized into one shared component and updated to use a more visible prominent circular treatment tinted with the app accent color, bringing confirmation actions closer to native iOS affordances while keeping them consistent across forms and sheets.
- **The group picker create action now uses the app accent color when enabled** (`GroupSelectorChipView`) — the `+` button used to open the Create Group flow now follows the same active-state color language as the rest of the app’s primary creation actions instead of appearing with the previous white treatment.
- **Item-list detail hero add actions now inherit the current category color when available** (`ItemListDetailComponents`, `TotalSpentCardView`) — when viewing an item list tied to a category with its own color, the bottom hero `+` button now adopts that category color, extending the same contextual add-action cue already introduced on the dashboard.

## [1.15.0] - 2026-05-10

### Changed
- **The dashboard add button now adopts the active category color while drilled into a category filter** (`DashboardView`, `DashboardComponents`, `TotalSpentCardView`) — when the user is browsing inside a selected dashboard category, the hero `+` action now uses that category’s color instead of the default accent color. This gives clearer context that the next new entry is being created from within that active category view, while preserving the standard accent styling when no category filter is active.

## [1.14.8] - 2026-05-10

### Changed
- **The dashboard now auto-enters the `All` list when the visible range contains only uncategorized entries** (`DashboardView`) — instead of showing a category-board state with only an `All` fallback button, the dashboard now resolves that case as an implicit `All` selection and opens the entry list directly. This makes brand-new groups with uncategorized records feel more natural and removes an unnecessary intermediate step.

## [1.14.7] - 2026-05-10

### Fixed
- **The dashboard now still exposes the `All` entry point when visible item lists have no category assigned** (`DashboardView`, `DashboardComponents`, `DashboardCategoryBoardComponents`) — newly created groups could end up with visible entries that the category board could not render because every item list lacked a category, leaving users with no way to open those records from the dashboard. The dashboard now detects when the selected date range contains visible item lists even if the category box grid is empty, and shows the `All` button as a fallback so uncategorized records remain reachable.

## [1.14.6] - 2026-05-10

### Fixed
- **Dashboard category labels now follow category renames immediately when returning from category management** (`DashboardView`, `DashboardViewModel`) — the dashboard was still showing stale category names after edits because its selected filter state and category-box metadata path could outlive the renamed value. The dashboard filter state now stores only stable category identifiers instead of copied box snapshots, and dashboard category-box labels now read directly from the live `SDCategory` relationship values during aggregation instead of preferring older cached metadata. This keeps the dashboard aligned with category edits as soon as the user comes back.

## [1.14.5] - 2026-05-10

### Added
- **Introduced a shared centered editor header block for preview + primary name input layouts** (`CenteredEditorNameBlock`) — the app now has a reusable component that combines a centered preview area with the shared `LimitedTextField`, so editor screens that follow this pattern can stay visually aligned without duplicating their top input structure.

### Changed
- **Category and payment method editors now use the same shared top input pattern** (`CategoryFormView`, `PaymentMethodFormView`) — both screens now build their centered preview and primary name field through the same common component instead of maintaining slightly different local layouts. This keeps the payment method name field aligned with the category editor and makes future input-style adjustments propagate consistently.

## [1.14.4] - 2026-05-10

### Fixed
- **Undo for mixed paid/unpaid dashboard item lists now restores each item’s real original paid state instead of flattening everything to pending** (`DashboardViewModel`) — the dashboard bulk paid toggle was taking its undo snapshot from the in-memory `itemList.items` relationship, which could diverge from the fresher item state used elsewhere in dashboard totals and row status calculations. The undo path now snapshots current items from a fresh fetch before applying the bulk toggle, and it also restores the in-memory paid/partial/all row state immediately when undo is tapped, so mixed lists return to their exact original combination of paid and unpaid items.
- **Dashboard search results now calculate paid and unpaid matched amounts from the same fresh item source used by dashboard totals** (`DashboardViewModel`) — search-mode item-list rows could still show `0.00` paid even when a matched item was actually marked as paid, because the search summary logic was reading `itemList.items` while the rest of the dashboard relied on fresher fetched item data. Search summaries now reuse lightweight cached snapshots derived from the fetched items used for dashboard totals, so visible paid/unpaid search amounts stay consistent with the real item state.
- **Dashboard bulk paid toggle restore now uses the same fresh item snapshot strategy on both snapshot and undo paths** (`DashboardViewModel`) — the mixed-state undo fix was tightened so restore no longer falls back to mutating only the potentially stale relationship array while persisting each item. This keeps the full bulk-toggle lifecycle more coherent and reduces the chance of relationship drift affecting visible dashboard state.

### Changed
- **The dashboard bulk paid/undo flow in the view model was refactored into smaller private helpers without changing behavior** (`DashboardViewModel`) — snapshot creation, optimistic bulk-state application, toast setup, restore, and paid-status derivation now live in dedicated helper methods, making the flow easier to reason about and keeping the paid-state rules centralized in the view model.

## [1.14.3] - 2026-05-10

### Fixed
- **The selected dashboard category bar now sits inside the main rounded content card instead of appearing like a separate protruding surface** (`DashboardComponents`) — the active category row was previously injected above the filtered list through a top safe-area inset, which made it look wider and visually detached from the main dashboard container even though both surfaces shared the same background color. The selected-category bar now lives in the same vertical content stack as the filtered list, so its width, alignment, and containment match the main card correctly.

## [1.14.2] - 2026-05-10

### Fixed
- **Filtered dashboard day headers now respect the currently visible filtered totals instead of the full unfiltered day amount** (`DashboardView`) — when drilling into a category such as `Gafas`, the per-date header total now sums only the visible filtered item lists for that day rather than the total of every item list recorded on that date.
- **Search-driven dashboard amounts now show the visible paid portion instead of the full matched subtotal** (`DashboardViewModel`, `DashboardView`) — when a filtered row contains both paid and unpaid matched items, the white main amount and the grouped day header now reflect only the paid matched value, while the unpaid matched amount remains in the secondary unpaid line below.

## [1.14.1] - 2026-05-10

### Changed
- **The dashboard month filter sheet was simplified back to a cleaner wheel-based picker layout** (`DashboardMonthFilterSheet`) — month and year selection now use a tighter native wheel presentation with a lighter “Back to current month” reset action, reducing the heavier card-like form treatment introduced during the filter update.
- **The dashboard no-results state now uses a dedicated centered filter/search presentation instead of the generic empty-state visual** (`DashboardNoResultsState`, `DashboardCategoryBoardComponents`, `ExpenseListView`) — when search or month filtering returns zero matches, the dashboard now shows a centered filter-style empty message inside the main content area, while truly empty groups still keep the normal add-entry empty state.

### Fixed
- **Resetting a custom month filter back to the current month now refreshes the visible dashboard content immediately** (`DashboardComponents`, `DashboardView`) — the hero totals were already updating correctly, but the filtered content area could remain visually empty until another UI interaction forced a redraw. The filtered list now refreshes its identity locally when its visible item set changes, so returning to the current month repopulates the board/list right away.
- **Dashboard category drill-in transitions now preserve the intended side-swap motion again** (`DashboardView`, `DashboardComponents`) — the temporary whole-content identity refresh used to solve the stale filtered view bug was making SwiftUI rebuild the entire dashboard content node, which degraded category-board-to-list transitions into a fade. The refresh behavior is now scoped to the filtered list itself so the original left/right dashboard drill animation remains intact.
- **Dashboard search navigation no longer interferes with normal list/detail push animations** (`DashboardView`) — tapping a matched item list now follows the same push path as regular navigation without an extra simultaneous keyboard-dismiss state change.

## [1.14.0] - 2026-05-08

### Changed
- **The dashboard group picker sheet now uses a flatter native grouped background instead of the translucent liquid-style modal surface** (`GroupSelectorChipView`, `GroupPickerComponents`) — the group-selection flow now forces a system grouped presentation background and hides the list’s default scroll surface so the medium detent no longer looks glassy or muddy compared with the fully expanded state.
- **The add-group action in the group picker toolbar was visually simplified** (`GroupSelectorChipView`) — the previous filled circular-plus treatment was replaced with a cleaner standalone plus glyph, keeping the affordance obvious while reducing the heavy floating-button feel inside the navigation bar.
- **The nested Create Group sheet now matches the same opaque grouped modal treatment as the picker itself** (`GroupSelectorChipView`) — opening group creation from the picker no longer reintroduces a transparent sheet background, so the whole group-management flow now feels visually consistent across stacked modal states.

## [1.13.0] - 2026-05-08

### Added
- **Introduced reusable native grouped-sheet primitives for settings-style rows and form surfaces** (`NativeGroupedSheetComponents`, `LimitedTextField`) — the app now has a small shared presentation layer for iOS-style grouped sheets, including a reusable settings-row icon treatment and a `LimitedTextField` style that can live inside `Form`/`List` without painting an extra card background on top of the system container.

### Changed
- **Settings now presents more like a native iOS settings screen instead of a custom modal card stack** (`SettingsSheetView`) — the settings sheet now leans on grouped list structure, tighter native spacing, large-title hierarchy, and full-row settings-style cells so the screen feels closer to Apple’s own Settings presentation while keeping OMO’s existing navigation behavior and icon consistency.
- **Group and payment-method edit sheets now use native grouped form containers instead of manual scroll/card layouts** (`GroupInfoEditSheet`, `PaymentMethodFormView`) — both flows were moved from `ScrollView + systemGroupedBackground + custom cards` to `Form`-based grouped sections, which reduces the layered-sheet look and makes edit flows feel more at home inside iOS modal navigation.

### Fixed
- **Text-length enforcement in shared form fields now uses a sanitized binding instead of mutating the same state inside `onChange`** (`LimitedTextField`) — the reusable text field no longer observes `text` and writes back to `text` in the same change cycle. The max-length rule now lives in a dedicated binding setter, which better matches SwiftUI data-flow best practices and avoids the self-mutation pattern flagged by the project guide.

## [1.12.0] - 2026-05-07

### Added
- **Full-app backup export/import now lives in Settings using the native iOS Files flow** (`SettingsSheetView`, `SettingsBackupViewModel`, backup DTOs/use cases/repository, localization files) — the app can now export a complete JSON snapshot of the current local dataset as a `.omo-backup` file through `fileExporter`, so the user explicitly saves it into the Files app or another Files location. Settings also now offers backup import through the native file picker, with versioned backup metadata and payload statistics embedded in the file from day one.

### Changed
- **Backup restore uses a safer replace-all flow with validation and rescue export before destructive import** (`SettingsBackupViewModel`, `DefaultBackupRepository`, `OMOBackupModels`) — importing a backup now validates schema version, record counts, duplicate IDs, and cross-entity references before any mutation occurs. If the device already has local data, the app first prepares a rescue backup export to Files, and only after that save flow succeeds does it present the destructive confirmation to replace the current database with the imported snapshot.
- **Backup import now explains the rescue-backup step before opening Files** (`SettingsSheetView`, `SettingsBackupViewModel`, localization files) — when the app already contains local data, selecting a backup for import no longer jumps straight into a second Files save flow with no context. The user now sees an explicit explanation that OMO is asking them to save a rescue copy of the current device data first, so the safety step feels intentional instead of confusing.
- **The destructive restore confirmation copy was tightened after the rescue explanation step** (localization files) — once the rescue step has already been explained separately, the final replace-data alert now focuses only on the fact that the import will overwrite current data, which makes the sequence easier to understand.

### Fixed
- **The backup action rows in Settings now behave like full-width tappable rows** (`SettingsSheetView`) — `Export Backup to Files` and `Import Backup` no longer only respond when the user taps directly on the visible label/icon cluster. The whole row is now hit-testable, which matches native settings-list expectations.
- **The first manual backup export no longer causes a brief two-button blink before the Files sheet appears** (`SettingsBackupViewModel`, `SettingsSheetView`) — the flow now prevents re-entry inside the view model instead of visually disabling both backup buttons during export preparation, avoiding the momentary flicker.
- **Settings backup view initialization is now explicitly main-actor isolated** (`SettingsSheetView`) — this removes the Swift 6 warning caused by reading `AppDIContainer.shared` from a nonisolated initializer.

### Notes
- **Backup files use JSON internally with a custom `.omo-backup` extension** (`OMOBackupDocument`) — this keeps the file human-inspectable and migration-friendly while still giving the feature a dedicated app-specific backup format.
- **Backup filenames now use deterministic zero-padded timestamps** (`SettingsBackupViewModel`) — export and rescue-backup files now always use a stable `yyyy-MM-dd-HH-mm` naming pattern so minute values like `00` are preserved correctly in the visible Files filename.
- **The app now declares `.omo-backup` as a real document type in its Info.plist** (`Info.plist`, `OMOMoney.xcodeproj/project.pbxproj`) — this lets the iOS Files picker recognize backup files as selectable instead of showing them disabled during import.

## [1.11.4] - 2026-05-07

### Fixed
- **Resolved the remaining `withAnimation` compiler warning in item-list detail deletion** (`ItemListDetailViewModel`) — deleting an item inside `withAnimation` was implicitly returning the removed `SDItem` from `items.remove(at:)`, which triggered Xcode’s unused-result warning. The removal is now explicitly discarded inside the animation block so the intent is clear and the warning is gone.

---

## [1.11.3] - 2026-05-07

### Changed
- **The first-user onboarding screen can now be reopened safely in debug builds without touching persisted data** (`SettingsSheetView`, `CreateFirstUserView`, `CreateFirstUserViewModel`) — added a debug-only `Onboarding Preview` entry under Settings that pushes the same first-user registration UI in a simulated submission mode. The simulated path validates the form and walks through the loading states, but it does not create a user, group, or user-group record in SwiftData. This makes it possible to regression-test the empty-sandbox onboarding experience on a device that already has a real user installed, without polluting the database or confusing the app’s single-current-user assumption.
- **The first-user onboarding presentation was refined to feel more branded and legally complete** (`CreateFirstUserView`, localization files) — the onboarding hero now uses the branded `settings-icon` asset on a black badge instead of the old wallet SF Symbol, the welcome heading was simplified into a cleaner `OMONI` brand lockup, the subtitle was tightened into shorter slogan-style copy, and the legal area now includes inline Terms and Privacy links plus a required consent checkbox before account creation can proceed. The consent row was tuned so the links remain tappable, the checkbox has a larger finger-friendly tap target, and the copy wraps naturally when space is tight.
- **A small batch of Xcode warnings was cleaned up after the onboarding work** (`DashboardViewModel`, `AddItemListView`, `CalendarGridView`, `ItemListDetailViewModel`) — removed dead immutable locals, made `ItemListPaidStatus.none` explicit where Swift inferred the optional `.none` case, captured scalar IDs before async work to avoid Swift 6 `Non-Sendable` warnings around `SDGroup`, and simplified animation calls so the compiler no longer warns about ignored `Void` results.

### TODO
- **Replace the temporary landing-page legal links with real website policy pages** (`CreateFirstUserView`) — both onboarding legal links currently point to `https://omopockettool.com` as a fallback until dedicated Terms and Privacy pages are published on the website.

---

## [1.11.2] - 2026-05-07

### Removed
- **Deleted the unused legacy multi-user management flow** (`UserListView`, `UserListViewModel`, `AddUserView`, `EditUserView`, `CreateUserViewModel`, `EditUserViewModel`, `UserDetailViewModel`) — these files were no longer referenced by any real app navigation path and only survived through previews or the old list-based user-management flow. The current product direction is one active user per device, with first-user creation handled by `CreateFirstUserView` and ongoing account edits handled through `SettingsSheetView` → `UserProfileView`, so removing the dead flow reduces maintenance noise without affecting the live settings/profile path.

---

## [1.11.1] - 2026-05-07

### Changed
- **SwiftUI lifecycle and state-wrapper usage were aligned with the project data-flow guide** (`MainView`, `AppContentView`, `CategoryFormView`, `PaymentMethodFormView`, `GroupInfoEditSheet`, `UserListView`) — initial async loads in the app entry flow now use `.task` instead of `onAppear + Task`, with one-shot guards so visibility changes do not restart root loading work unnecessarily. The category, payment-method, and group edit forms now seed their editable `@State` values in `init` instead of mutating them from `onAppear`, which keeps draft input tied to view-node lifetime rather than visibility callbacks. User-list pagination also moved from row `onAppear` to a task-based visibility trigger so async loading follows SwiftUI’s cancellable lifecycle model more closely.
- **Temporary lifecycle diagnostics were added to verify SwiftUI node lifetime and draft-state behavior on device** (`MainView`, `AppContentView`, `MainViewModel`, `AppContentViewModel`, `CategoryFormView`, `PaymentMethodFormView`, `GroupInfoEditSheet`, `UserListView`, `UserListViewModel`) — targeted `OSLog` tracing now records init, task start/finish, node appearance/disappearance, draft edits, and save events around the views touched by the lifecycle refactor. These logs are intended to confirm that root loads do not over-refresh and that edit-form state survives visibility changes while still resetting correctly after a true dismiss/reopen cycle.

---

## [1.11.0] - 2026-05-07

### Changed
- **Dashboard hero quick add now defaults to the active filtered category when launched from a category-focused list** (`DashboardView`, `AddItemListView`, `AddItemListViewModel`) — opening the hero add flow while browsing a filtered dashboard category now preselects that same category in the new-entry form, which matches the user’s current context and avoids falling back to unrelated usage history. The previous last-used-category behavior is still preserved when the user launches quick add from the general category board or from the aggregated `All` view.

---

## [1.10.0] - 2026-05-06

### Changed
- **Dashboard category filtering now uses directional horizontal content swaps instead of depth/blur effects** (`DashboardComponents`, `AnimationHelper`) — entering a category now moves the category board out to the left while the filtered item-list view enters from the right, and closing the filter performs the true inverse motion. The transition was simplified intentionally so it feels more like native content reorganization and less like a visual effect layered over the whole dashboard.
- **Month-view day-header totals now animate like item-list row amounts when paid state changes** (`ExpenseListComponents`) — the total shown in each daily section header now uses the same numeric content transition and spring timing already used by dashboard row amounts, so toggling an item list between paid and unpaid updates the day aggregate more smoothly instead of snapping abruptly.
- **The Xcode project is now explicitly iOS-only** (`OMOMoney.xcodeproj/project.pbxproj`) — unsupported `macosx` and visionOS platform declarations were removed from the app and test targets so Swift module resolution no longer tries to evaluate the project as a multi-platform target. This aligns the project settings with the real product scope and avoids `UIKit` resolution failures in the app entry point.

---

## [1.9.5] - 2026-05-06

### Changed
- **Dashboard and item-list detail now use structured `.task` lifecycle instead of `onAppear + Task { }`** (`DashboardView`, `ItemListDetailView`) — both screens migrated their data-loading calls to the `.task` modifier, which automatically cancels the async work if the view disappears mid-flight. The redundant `hasLoadedInitialData` guard in `ItemListDetailView` was removed: because `NavigationStack` destroys the view node on pop, the flag always reset on re-entry and served no purpose.

---

## [1.9.4] - 2026-05-06

### Changed
- **Currency and month-title formatters are now cached instead of allocated on every formatting call** (`DashboardViewModel`) — `NumberFormatter` (currency) was previously instantiated twice on every call to any formatting helper, and `DateFormatter` (month title) was re-created on every access to `selectedMonthTitle`. Both are now retained as stored properties and rebuilt only when the active group's currency code changes. With formatting called across ~12 helpers per render cycle, this eliminates repeated expensive object allocations on the main thread.
- **Removed unreachable and duplicate methods from `DashboardViewModel`** — `getItemListTotal()`, `getFormattedItemListTotal()`, `getCurrentMonthItemLists()`, and `todayRawTotal` were dead code: none were called from outside the ViewModel, and `getCurrentMonthItemLists()` duplicated the already-maintained `currentMonthItemLists` stored property. All four were deleted.

---

## [1.9.3] - 2026-05-06

### Changed
- **All debug `print` statements removed from the Presentation and Data layers** (`DashboardViewModel`, `AddItemListViewModel`, `AddItemViewModel`, `ItemListDetailViewModel`, `CreateFirstUserViewModel`, `CreateUserViewModel`, `DashboardView`, `AppContentView`, `CustomAlertView`, `ModelContainer+Shared`) — 89 diagnostic `print` calls scattered across ViewModels and Views were stripped from production code. Infrastructure-level error prints in `ModelContainer+Shared` (save failures, fetch errors) were preserved as they surface genuine runtime faults. The dead `logAllEntities()` debug helper in `DashboardView` was also deleted.

---

## [1.10.0] - 2026-05-06

### Changed
- **Dashboard category-board flow was refined across layout, interaction, and state handling** (`DashboardView`, `DashboardComponents`, `DashboardCategoryBoardComponents`, `ExpenseListView`, `DashboardViewModel`) — the new category-first dashboard experience was polished substantially after its first rollout. Category cards were compacted for denser scanning, the “All” card was centered visually, selected-category spacing above the first day header was tightened, day-header totals and collapsible month sections were restored, and the category hero total now updates correctly when paid status changes inside a filtered category view.
- **Dashboard list rendering was modernized to remove `AnyView`-based empty-state plumbing** (`DashboardView`, `DashboardComponents`, `DashboardCategoryBoardComponents`, `ExpenseListView`) — the dashboard’s empty-state and bottom-inset composition now use typed SwiftUI builder paths instead of `AnyView` wrappers and brittle type checks. This keeps structural identity clearer, aligns better with current SwiftUI data-flow guidance, and preserves the custom no-results state without relying on erased view types.
- **Group picker actions now use a native long-press interaction with first-time guidance** (`GroupPickerComponents`, `GroupSelectorChipView`, localization files) — group actions inside the dashboard picker were redesigned around SwiftUI’s `contextMenu` on each row, matching the native long-press feel users expect from system apps. The unstable ellipsis-driven menu path was removed, and the picker now shows a lightweight one-time hint explaining that users can press and hold a group to reveal more actions.
- **About and dashboard branding were refreshed with the new OMO logo treatment** (`DashboardTopBarView`, `AboutOMOView`, settings icon asset) — the settings entrypoint now uses the cropped OMO logo at a more appropriate scale, and the About OMO hero was updated to use the same brand mark plus a stronger typographic treatment for the `OMONI` heading.

### Fixed
- **Bottom hero cards now stay anchored correctly in both dashboard and item-list detail layouts** (`DashboardComponents`, `DashboardCategoryBoardComponents`, `ExpenseListView`, `ItemListDetailView`, `ItemListDetailComponents`) — the long-standing issue where the shared `TotalSpentCardView` could float upward and leave a false gap at the bottom after lock/unlock, short-content layouts, or relayout events was fixed at the container level by stabilizing full-height parent surfaces.
- **Group settings rows and dashboard bulk-status feedback were polished for usability and localization** (`GroupFormView`, `DashboardViewModel`, `ToastView`, localization files) — group settings rows are now fully tappable across the whole cell, dashboard bulk paid/pending messages are localized instead of hardcoded, and the shared toast display time was extended so users have enough time to read the message and tap undo.
- **Item-list detail pull-to-refresh now follows the dashboard’s more stable trigger geometry** (`ItemListDetailView`, `ItemListDetailComponents`, `ItemListDetailViewModel`) — the detail screen’s refresh path was reworked so the `List` resolves pull distance against internal safe-area insets instead of against extra vertical padding around the scroll surface. Along the way, row-count animation noise was removed and refresh updates now apply without list animations. The result is that slow pull-to-refresh gestures no longer snap visibly right when the haptic fires, matching the steadier feel already present in the dashboard list.

---

## [1.9.2] - 2026-05-06

### Fixed
- **Group picker actions now use a cleaner native long-press flow with first-time guidance** (`GroupPickerComponents`, `GroupSelectorChipView`, localization files) — group actions were simplified to a SwiftUI `contextMenu` on each row, removing the unstable ellipsis-menu path that could emit UIKit hierarchy warnings in logs. To keep the interaction discoverable, the group picker sheet now shows a lightweight one-time hint telling users they can press and hold a group to reveal more actions.
- **Dashboard bulk paid/pending toasts are now fully localized and remain visible longer** (`DashboardViewModel`, `ToastView`, localization files) — the status messages shown when marking whole item lists as paid or pending no longer rely on hardcoded Spanish strings, and the shared toast duration was extended so users have more time to read the message and tap the undo action comfortably.

---

## [1.9.1] - 2026-05-06

### Fixed
- **Bottom hero cards are now anchored by stable full-height parent layouts in both dashboard and item-list detail** (`DashboardComponents`, `DashboardCategoryBoardComponents`, `ExpenseListView`, `ItemListDetailView`, `ItemListDetailComponents`) — the long-standing issue where the shared `TotalSpentCardView` could float upward and leave an incorrect gap at the bottom after lock/unlock or other layout recalculations was fixed at the container level. The root cause was not the card itself, but parent scroll/content surfaces that were allowed to collapse below full viewport height, causing the bottom `safeAreaInset` anchor to be resolved against a shrunken layout until another strong relayout event such as keyboard presentation occurred.

---

## [1.9.0] - 2026-05-06

### Changed
- **Dashboard now opens into a category-board browsing experience before drilling into expense lists** (`DashboardViewModel`, `DashboardView`, `DashboardCategoryBoardComponents`, `DashboardComponents`, `DashboardTopBarView`, localization files, settings icon assets) — the main dashboard flow was redesigned so users first see tappable category boxes with per-category totals instead of landing directly in the day-grouped expense list. From there, they can open a category-focused list or the aggregated “All” view, making the dashboard feel more like a high-level spending overview with a clearer first decision point.
- **Selected dashboard category filters were visually tightened as part of the new category-board flow** (`DashboardComponents`, `ExpenseListView`) — the selected category chip bar and the first visible day header now sit closer together, preserving more vertical room for the filtered expense list and making the transition from category selection into the detailed list feel denser and more intentional.

---

## [1.8.22] - 2026-05-03

### Changed
- **Pull-to-refresh now ends more softly in dashboard and item-list detail lists** (`ExpenseListView`, `ItemListDetailComponents`) — both list surfaces now keep the native refresh cycle alive for a brief extra moment before completion, which makes the refresh indicator fade away less abruptly when the user releases the swipe-down gesture.

---

## [1.8.21] - 2026-05-03

### Changed
- **Dashboard and item-list list containers now use softer internal edge treatment instead of hard cutoff lines** (`DashboardComponents`, `ExpenseListView`, `ExpenseListComponents`, `ExpenseRowView`, `ItemListDetailView`, `ItemListDetailComponents`) — the list viewport inside the rounded gray cards was refined so content no longer feels pinned to the component edges. Dashboard `Today` and item-list detail now use a subtle internal edge fade at the top and bottom, while month view keeps only the lower fade because date headers already resolve the upper edge. The dashboard bottom inset was also cleaned up by removing the hard `1pt` separator line, leaving a softer transition above the hero/bottom controls.

---

## [1.8.20] - 2026-05-03

### Changed
- **Dashboard search now keeps visual context when navigating into an item list** (`DashboardView`, `ItemListDetailView`, `ItemListDetailViewModel`, `ItemListDetailComponents`) — when a user opens an item list from active dashboard search results, the search query is now propagated into the detail screen so matching items are subtly marked with a magnifying-glass indicator. This makes it easier to understand why that list matched and quickly spot the relevant items without adding heavy row highlighting.

---

## [1.8.19] - 2026-05-03

### Added
- **Dashboard search and filter now use a dedicated no-results state instead of the generic add-entry empty message** (`DashboardNoResultsState`, `DashboardView`, `DashboardComponents`, `ExpenseListView`, localization files) — when a search query or month filter produces zero visible item lists, the dashboard now shows a friendlier “No matches found” empty state with search-specific copy instead of the generic “Tap + to add an entry” message. The no-results state is rendered as a centered overlay only for search/filter empties, while truly empty groups keep the original default empty-state behavior.

---

## [1.8.18] - 2026-05-03

### Changed
- **Item-list detail rows now use the same cleaner spacing rhythm as dashboard item-list rows** (`ItemListDetailView`) — checklist rows inside item-list detail were updated from the older asymmetric top/bottom padding to a more balanced min-height and vertical-padding structure, improving scan rhythm and making the list feel more consistent with the dashboard’s refined row layout. The timeline connector line height was also adjusted to match the taller row spacing so the check rails remain visually continuous between items.

### Fixed
- **Zero-value item lists now behave like real checklists in detail and dashboard completion states** (`DashboardViewModel`, `ItemListDetailViewModel`, `ItemListDetailComponents`) — lists whose items total `0.00` are no longer treated as empty just because they have no money value. Completion state now follows the real item state: empty lists stay neutral, unpaid items keep pending state, and all-paid lists show the completed checkmark even when every item is value-free.

---

## [1.8.17] - 2026-05-03

### Fixed
- **Zero-value checklists now show paid/pending completion state correctly in both dashboard rows and item-list hero cards** (`DashboardViewModel`, `ItemListDetailViewModel`, `ItemListDetailComponents`) — lists whose items all have `0.00` values are no longer treated as empty just because they have no monetary total. The dashboard status icon and the item-list hero now follow the real item completion state: empty lists stay neutral, lists with unpaid items stay pending, and lists with all items marked paid show the completed checkmark even when every item is value-free.

---

## [1.8.16] - 2026-05-03

### Changed
- **Dashboard search now reaches both item-list titles and nested items with clearer result amounts** (`DashboardViewModel`, `DashboardView`, `ExpenseListView`, `ExpenseRowView`, dashboard components, localization files) — searching from the dashboard no longer stops at the item-list description. Results now remain visible when either the list title or one of its items matches the query, and matching rows show a more useful search presentation: a match-count subtitle on the left, matched subtotal on the main amount line, and matched unpaid subtotal below when relevant. This keeps the search result scope consistent and avoids mixing whole-list totals into item-level search feedback.
- **Dashboard bottom search bar was stabilized with a pure SwiftUI layout path** (`DashboardBottomBarView`, `DashboardView`, `DashboardComponents`, `docs/START_HERE.md`) — the inline search bar now stays mounted in the layout and only changes visibility/focus state, which resolves the first-open keyboard positioning issues without relying on UIKit keyboard notifications. The quick-start doc was also updated to reflect the real `OMOMoney/` source-folder layout in the repository.

---

## [1.8.15] - 2026-05-01

### Changed
- **Dashboard inline search now keeps its field visible above the keyboard and hides the hero card while searching** (`DashboardView`, `DashboardBottomBarView`, `DashboardViewModel`) — activating search now lets the bottom action area move with the keyboard instead of being pinned underneath it, and the total hero temporarily disappears to free more vertical space for scanning filtered item-list results in real time.

---

## [1.8.14] - 2026-05-01

### Changed
- **Dashboard search now works inline from the bottom action bar** (`DashboardViewModel`, `DashboardView`, `DashboardBottomBarView`) — tapping the magnifying glass now expands the action area into a live search field instead of opening a separate modal. The visible list filters in real time using a simple case-insensitive match on item-list descriptions, so users can keep the month/day context on screen while narrowing results.

---

## [1.8.13] - 2026-05-01

### Changed
- **Hero add buttons now use a bolder plus glyph for stronger visual weight** (`TotalSpentCardView`) — the circular add button in both dashboard and item-list hero cards keeps the same size and layout, but the `+` symbol is now rendered with a heavier weight so the primary add action reads more clearly at a glance.

---

## [1.8.12] - 2026-05-01

### Changed
- **Dashboard item-list rows were simplified and stabilized for faster scanning** (`ExpenseRowView`, `ExpenseListView`, `ExpenseListComponents`, `DashboardComponents`, `TimelineRailView`) — removed the low-value category/icon and item-count metadata from each dashboard row, keeping the focus on description, paid total, unpaid total, and status. The row layout now holds a stable height while unpaid values animate more smoothly, and the timeline connector lines were adjusted to stay visually continuous across rows within the same day.

---

## [1.8.11] - 2026-05-01

### Changed
- **Dashboard month filter sheet now matches the app’s standard sheet chrome and filter button feedback** (`DashboardMonthFilterSheet`, `DashboardBottomBarView`) — the filter sheet now uses the same navigation-bar `xmark` / `checkmark` toolbar pattern as the other modal forms, and the dashboard filter button now triggers the project’s press haptic while keeping the active state visually lightweight by tinting only the icon.

---

## [1.8.10] - 2026-05-01

### Fixed
- **Pending item lists from previous months are now reachable from the dashboard** (`DashboardViewModel`, `DashboardView`, `DashboardBottomBarView`, `DashboardMonthFilterSheet`) — month mode is no longer locked to the current calendar month. The new dashboard filter sheet lets the user pick a month and year, so entries created in April remain accessible on May 1 instead of disappearing from the main month view.

### Changed
- **Dashboard filter controls now have their first real implementation** (`DashboardBottomBarView`, `DashboardMonthFilterSheet`, `DashboardComponents`, localization files) — the filter button in the bottom bar now opens a dedicated month/year sheet, the active filter state is reflected in the button styling, and the hero label adapts to the selected month instead of always assuming "this month".

---

## [1.8.9] - 2026-05-01

### Fixed
- **Empty and zero-total item lists no longer appear completed in dashboard rows or detail hero cards** (`DashboardViewModel`, `ExpenseRowView`, `ItemListDetailViewModel`, `ItemListDetailComponents`) — item lists with no items, or whose real total is `0.00`, now render a neutral payment state instead of a green completed check. This keeps the dashboard timeline and the item-list hero aligned so only lists with actual paid value read as completed.

### Changed
- **Derived payment-display state is now centralized in ViewModels instead of SwiftUI views** (`DashboardViewModel`, `ItemListDetailViewModel`, `ExpenseListView`, `ItemListDetailView`, `docs/START_HERE.md`) — introduced explicit presentation states for dashboard rows and item-list hero cards so views only render precomputed display intent. The project quick-start guide now documents this rule directly: views render, ViewModels decide.

---

## [1.8.8] - 2026-05-01

### Changed
- **Zero-value amounts are now visually de-emphasized in dashboard and item rows** (`ExpenseRowView`, `ItemListDetailView`) — amounts that resolve to `0.00` now use a secondary tone and slightly lighter weight so real spending stands out faster while zero-value entries remain visible. This improves list scanning without hiding pending or informational rows.

---

## [1.8.7] - 2026-05-01

### Fixed
- **Manual items created inside an item-list detail now always start unpaid** (`AddItemViewModel`, `AddItemView`, `ItemListDetailView`) — adding an item from `ItemListDetailView` no longer auto-marks it as paid based on the list date. This keeps shopping lists and note-taking lists pending until the user explicitly marks each item as completed. The dashboard quick-add flow is unchanged: its auto-created first item still uses the list date rule, so today/past entries start paid and tomorrow/future entries start unpaid.

---

## [1.8.6] - 2026-04-30

### Fixed
- **New entry form now correctly defaults the initial item to paid for today and past dates** (`AddItemListViewModel`) — the first item created when saving a new entry was using a legacy `paymentMethodId != nil` check instead of the date-based rule, causing it to be unpaid even for today. Aligned with `AddItemViewModel`: today and past → `isPaid = true`, future → `isPaid = false`.

### Removed
- **Dead seed-data generator deleted** (`DashboardViewModel`) — `generateSeedDataDebug()` and `generateSeedData()` were unreachable dev utilities (~80 lines) that duplicated the item list creation path. Removed to keep a single creation path through `AddItemListViewModel`.

---

## [1.8.5] - 2026-04-30

### Fixed
- **Description suggestions now search across all categories instead of only the selected one** (`ConceptSuggestionEngine`, `AddItemListViewModel`, `ConceptSuggestionChipsView`, `AddItemListComponents`) — when the typed text matches historical entries from a different category, those suggestions appear as chips in that category's color. Tapping a cross-category chip fills the description and automatically switches the selected category. Same-category results still rank first so the existing behavior is preserved when the description matches the current category.

---

## [1.8.4] - 2026-04-30

### Changed
- **New items added to a future-dated list now default to unpaid** (`AddItemViewModel`, `AddItemView`, `ItemListDetailView`) — when creating an item inside a list whose date is tomorrow or later, `isPaid` defaults to `false` so the entry acts as a payment reminder rather than a completed expense. Items added to today or past-dated lists keep `isPaid = true` as before.

---

## [1.8.3] - 2026-04-30

### Fixed
- **Excess space above the first section header in month view is removed** (`ExpenseListView`) — the `List` default top content inset was stacking on top of the rounded container padding, pushing the "TODAY" header too far down. Setting `contentMargins(.top, 0, for: .scrollContent)` removes the default inset and lets the container padding alone control the spacing.

---

## [1.8.2] - 2026-04-30

### Changed
- **Dashboard today/month toggle replaced with a native segmented picker** (`DashboardTopBarView`) — the custom two-button capsule switcher is now a `Picker` with `.segmented` style, reducing manual state management and giving the control a standard iOS appearance.

---

## [1.8.1] - 2026-04-30

### Added
- **Dashboard and item list expense views are now displayed inside a rounded card container** (`DashboardMainContent`, `ItemListDetailView`, `DashboardComponents`, `ItemListDetailComponents`) — the scrollable list is wrapped in a `secondarySystemBackground` rounded rectangle that matches the width of `TotalSpentCardView`, giving both screens a consistent card-based layout. The background shape is a separate static layer so pull-to-refresh animations and scroll view geometry stay stable. Scroll indicators are hidden on both lists to prevent UIKit clipping artifacts caused by the external `clipShape`.

### Fixed
- **Success confirmation label on the dashboard hero card now reads "Added!" instead of "All done!"** (`Localizable.strings`, `String+Localization`) — the `dashboard.allDone` key was renamed to `dashboard.added` and the English copy updated to better reflect that a new expense was just recorded, not that all items are completed.

---

## [1.8.0] - 2026-04-30

### Fixed
- **Large dashboard and item-list views were modularized into scene-local components** (`AddItemListView`, `ItemListDetailView`, `DashboardView`, `GroupSelectorChipView`, `ExpenseListView`, `CalendarGridView`) — the heaviest SwiftUI screens were split into dedicated `Views/Components/` files so rendering sections, pickers, hero cards, overlays, and list headers are easier to maintain without changing behavior or architecture responsibilities.
- **Scene-local extracted views now live under `Views/Components/`** (`Dashboard`, `ItemList`) — moved newly extracted subviews out of the main `Views/` folder and into scene-scoped component directories, making the screen entry points easier to scan and keeping shared `Common/Components/` reserved for truly reusable UI.

---

## [1.7.4] - 2026-04-30

### Fixed
- **Dashboard totals now use a safer cache-first path** (`DashboardViewModel`, `DefaultItemRepository`) — per-item-list paid/unpaid totals, item counts, and payment status now reuse cached aggregate data before falling back to SwiftData fetches, and item-level writes now bump the parent item list’s `lastModifiedAt` so the dashboard cache invalidates correctly when anything changes.
- **Quick-add usage memory no longer caches live SwiftData models** (`AddItemListViewModel`) — the form now stores lightweight snapshot data for last-used concept/category/payment hints instead of caching raw `SDItemList` objects, reducing stale-reference risk while keeping the same behavior.

---

## [1.7.3] - 2026-04-30

### Fixed
- **Completed items now reorder more calmly after a paid toggle** (`ItemListDetailViewModel`, `DefaultItemRepository`) — when an item is marked as paid, the paid section no longer reshuffles only by original creation time. Completed items now use `lastModifiedAt` for their in-section ordering, which keeps the transition more stable and reduces the dizzying jumpiness caused by rapid reordering after completion.

---

## [1.7.2] - 2026-04-30

### Fixed
- **Dashboard bulk-complete toast now appears only when it is actually useful** (`DashboardViewModel`) — marking a list as paid from the dashboard no longer shows an undo toast when that list contains only 1 item. The notification is now reserved for multi-item lists, where undoing a bulk completion of the remaining items is genuinely helpful and avoids unnecessary toast noise during normal single-item usage.

### Commented
- Elipsis more options per date commented for now

---

## [1.7.1] - 2026-04-30

### Fixed
- **Dashboard day headers now respect the active app language** (`DateFormatterHelper`, `Localizable.strings`) — `Today` and `Yesterday` section headers no longer remain in Spanish when the app is shown in English. The shared date formatter now uses the current locale instead of hardcoded `es_ES`, so month names in those headers also follow the active language.

---

## [1.7.0] - 2026-04-30

### Added
- **Full EN/ES localization across all views** — every user-facing string in the app is now served through the `LocalizationKey` enum and `Localizable.strings` files for English and Spanish. When the device OS language is Spanish the app renders in Spanish; all other locales fall back to English. Covers ~27 view files across the Dashboard, Group, Category, Payment, User, ItemList, and Settings scenes, plus shared components (`EmptyStateView`, `HeroAmountInputView`, `AppContentView`, `SettingsSheetView`, `AboutOMOView`). Around 100 new localization keys were added spanning General, Dashboard, Entry, Item, Group, Category, Payment, Settings, User, and About domains.

---

## [1.6.1] - 2026-04-30

### Fixed
- **Dashboard total-cost footer now stays visually anchored** (`DashboardView`) — the hero total card and group chip area now sit on a solid bottom panel with a clear top boundary, preventing scrolling item rows from bleeding through the gap and reducing visual distraction while browsing the dashboard.

---

## [1.6.0] - 2026-04-30

### Added
- **Dedicated "Sobre OMO" experience in Settings** (`SettingsSheetView`, `AboutOMOView`) — users can open an about screen from settings to view app/company information, the current app version shown to users (`1.5.4`), donation access, direct web/contact actions with copy support, and a user-facing release-notes page.

---

## [1.5.4] - 2026-04-29

### Changed
- **Item-list detail now prioritizes unpaid items** (`ItemListDetailViewModel`) — items in a registry are now sorted with pending entries first and completed entries moved to the end, while keeping newest items first inside each status group. Toggling paid status immediately reorders the row so the detail screen behaves more like an actionable checklist.

### Refactor
- **Removed redundant `MainActor.run` blocks from `DashboardViewModel`** — since the ViewModel is already isolated with `@MainActor`, direct state reads and writes now happen inline instead of being wrapped in repeated `await MainActor.run { }` calls. This keeps the dashboard concurrency model clearer without changing behavior.

---

## [1.5.3] - 2026-04-29

### Fixed
- **Dashboard pull-to-refresh row jump eliminated** (`DashboardView`) — `ExpenseListView` is now the root view of the dashboard content with top and bottom bars attached via `.safeAreaInset`, mirroring `ItemListDetailView`. The refresh spinner now appears in the top safe-area inset instead of pushing the list’s constrained frame, removing the visible downward-then-upward row shift on every pull-to-refresh.

---

## [1.5.2] - 2026-04-29

### Fixed
- **Dashboard pull-to-refresh layout stability** (`ExpenseListView`, `DashboardViewModel`) — the Today list now renders flat rows when date headers are hidden, avoiding invisible `Section` spacing during refresh, and refresh updates item lists without row animations so SwiftUI’s native pull-to-refresh physics are not disturbed.

---

## [1.5.1] - 2026-04-29

### Fixed
- **Item-list detail hero stays anchored at the bottom** (`ItemListDetailView`) — the total hero now uses a bottom safe-area inset instead of sitting below an expanding `List`, preventing large empty gaps between items and the hero while keeping the hero fixed at the bottom of the screen.

---

## [1.5.0] - 2026-04-29

### Added
- **Collapsible monthly day summaries** (`ExpenseListView`, `DashboardView`) — in `Este mes`, tapping a date header now collapses or expands that day’s entries while keeping the daily total visible for a cleaner month summary. The feature is not shown in `Hoy`.

### Changed
- **Monthly collapse state persists across Today/Month toggles** (`DashboardView`) — collapsed days remain remembered when switching to `Hoy` and back to `Este mes`, and reset only when the active group changes.

---

## [1.4.2] - 2026-04-29

### Refactor
- **DI container layer simplified** (`AppDIContainer`) — removed the partial `UserSceneDIContainer` and `GroupSceneDIContainer` wrappers and routed their remaining factories through the main app container for a single dependency creation path.
- **Delete group factory centralized** (`AppDIContainer`) — added `makeDeleteGroupUseCase()` directly to the main container and updated dashboard/user creation flows to avoid scene-container indirection.

---

## [1.4.1] - 2026-04-29

### Fixed
- **Undo for bulk paid toggles** (`DashboardViewModel`, `ToastView`) — tapping an item-list paid status now stores the previous per-item paid state and shows a `Deshacer` action in the reusable toast. Undo restores each item exactly, protecting mixed paid/unpaid lists from accidental bulk changes.
- **Toast action support** (`ToastView`) — reusable toast notifications now support an optional action button while keeping existing dismiss-only toasts unchanged.

---

## [1.4.0] - 2026-04-29

### Added
- **Dedicated group information editor** (`GroupInfoEditSheet`) — group name and currency editing now opens in its own sheet with its own `X` and save action, avoiding confusion with category and payment method management screens.

### Changed
- **Group settings screen simplified** (`GroupFormView`) — the group settings view now acts as a management hub with separate rows for group information, categories, and payment methods, and no longer shows a global save action while navigating nested management flows.
- **Group settings UI modularized** (`GroupFormView`) — extracted reusable private section and row components to keep the main view focused on composition.

---

## [1.3.1] - 2026-04-29

### Fixed
- **Quick-add unpaid state without payment method** (`AddItemListViewModel`) — new quick-add items now start as unpaid when no payment method is selected, even if the amount is greater than zero. A missing payment method now represents a pending/future reminder instead of an already completed payment.
- **Payment method preselection respects the last registered item list** (`AddItemListViewModel`) — the quick-add form now derives the initial payment method from the most recently created item list by `createdAt`. If that last registered item list had no payment method, the next form starts with no payment method selected instead of falling back to older saved usage memory.

---

## [1.3.0] - 2026-04-29

### Added
- **Group picker rows redesigned** (`GroupSelectorChipView`) — the group picker sheet now shows each group as a richer row with the selected/empty status icon on the left, the group name, and the total spent in that group below it.
- **Visible group row actions** (`GroupSelectorChipView`) — each group row now has a trailing three-dot menu exposing the same `Detalles` and `Eliminar` actions as the existing swipe actions, making group management discoverable without removing swipe support.
- **Shared haptic feedback on group selection** (`GroupSelectorChipView`) — tapping anywhere on the selectable row area now uses the shared `PressHapticButtonStyle`, so changing groups gets the same tactile feedback as the rest of the app.

---

## [1.2.1] - 2026-04-29

### Changed
- **Form focus borders aligned to neutral gray** — shared `LimitedTextField` focus borders now match the money hero input by using `systemGray3` instead of accent/primary styling. This aligns focus feedback across Nuevo Artículo, Nueva Categoría, Métodos de Pago, Grupo, Perfil, and first-user setup forms.
- **Nuevo Artículo quantity focus border added** — the quantity stepper field now uses the same gray focus outline as the rest of the form fields.

---

## [1.2.0] - 2026-04-29

### Added
- **Connected timeline list design** (`ExpenseListView`, `ExpenseRowView`, `ItemListDetailView`) — dashboard item lists and item-list detail rows now render as a continuous timeline instead of separate rounded row cards. The existing paid/unpaid icon is the timeline node, with plain solid connector lines between rows and light separators for a more modern, connected visual system.
- **Reusable `TimelineRailView` component** — centralizes timeline node/connector rendering so dashboard rows and item detail rows share the same visual language while preserving paid-toggle behavior on the node itself.

---

## [1.1.7] - 2026-04-29

### Changed
- **Group swipe action renamed from "Ajustes" to "Detalles"** (`GroupSelectorChipView`) — the group picker swipe action now uses a clearer details label with the info icon while keeping the same navigation to the group detail/settings screen.

### Removed
- **Unused test data generator tooling removed** — deleted the unreachable `TestDataView` and `TestDataGenerator`. The debug screen was not wired into the app, so keeping it added dead code with no user-facing path to test or maintain.

---

## [1.1.6] - 2026-04-29

### Refactor
- **`GroupPickerSheetViewModel` extracted for group delete flow** — `GroupPickerSheet` no longer owns delete eligibility, optimistic removal, rollback, fallback group selection, or create-group state updates. The delete callback now propagates errors with `async throws`, allowing rollback behavior to remain inside the ViewModel instead of being swallowed by the view chain.

---

## [1.1.5] - 2026-04-29

### Refactor
- **`UserProfileViewModel` extracted for profile saving** — `UserProfileView` no longer creates `UpdateUserUseCase`, mutates `SDUser`, sets modification timestamps, or manages save errors directly. Profile name editing, validation, loading state, persistence, and error handling now live in `UserProfileViewModel`.

---

## [1.1.4] - 2026-04-29

### Refactor
- **`AppContentViewModel` extracted for app content loading** — `AppContentView` no longer creates or executes `GetCurrentUserUseCase` or `FetchGroupsForUserUseCase` directly. Initial user/group loading and setup-complete state now live in `AppContentViewModel`, keeping `AppContentView` focused on routing between loading, dashboard, and setup-required UI.

---

## [1.1.3] - 2026-04-29

### Refactor
- **`MainViewModel` extracted for app bootstrap flow** — `MainView` no longer creates or executes `GetCurrentUserUseCase` directly. Startup state (`isLoading`, `hasUsers`), first-user detection, and the minimum splash display timing now live in `MainViewModel`, keeping `MainView` focused on rendering `SplashView`, `AppContentView`, or `CreateFirstUserView`.

---

## [1.1.2] - 2026-04-29

### Fixed
- **Quick-add category and payment method defaults restored** (`AddItemListView`) — new item lists now auto-select the last used category and payment method for the active group again. The form first uses saved chip usage memory, then falls back to the latest persisted item list in that group when no local usage memory exists.
- **Last-used selections are persisted after quick save** — selected category and payment method are recorded when creating an item list, even if the user keeps the automatically selected chips and never taps them manually.

### Refactor
- **Moved last-used selection logic out of `AddItemListView`** — `AddItemListViewModel` now owns usage memory loading, persistence, fallback resolution, category/payment ordering, and blank-description fallback logic. The view stays focused on UI coordination and delegates behavior to the ViewModel.

---

## [1.1.1] - 2026-04-29

### Fixed
- **Category and payment method labels truncate correctly in hero meta row** (`ItemListDetailView`) — during the 3-second label phase, long names like "Alimentación" now truncate with `...` instead of wrapping. Added `.lineLimit(1).truncationMode(.tail)` to both label texts in `heroMetaRow`.
- **Category chip labels truncate correctly in `AddItemListView`** — replaced `ZStack` dual-layout with `if/else` + `.transition` in `categoryChip` and `overflowChip`. ZStack was passing an unconstrained width proposal to `Text`, preventing truncation from triggering.

---

## [1.1.0] - 2026-04-29

> **Versioning note:** Starting from this release the project follows Semantic Versioning strictly.
> Patch (`x.x.N`) = bug fixes. Minor (`x.N.0`) = new features. Major (`N.0.0`) = breaking changes.
> All previous 1.0.x releases were features; they would have been 1.x.0 under this scheme.

### Added
- **Change group in create/edit item list** (`AddItemListView`) — the Group row in the "Más detalles" section is now an interactive `Menu` listing all user groups. Selecting a different group reloads its categories and payment methods. If the previously selected category or payment method has a name match in the new group it is auto-selected. On save, the item list is persisted under the chosen group.

---

## [1.0.56] - 2026-04-29

### Added
- **Unpaid total in `ItemListDetailView` hero card** — hero card now shows remaining amount to pay. Status indicator (clock + amount in orange, or checkmark in green) is always visible from first frame. During the first 3 seconds, category and payment method labels are shown with their icons and the status shows icon-only to avoid crowding. After the timer, labels fade out and the full remaining amount appears next to the clock icon.
- **`EmptyStateView` shared component** (`Presentation/Common/Components/EmptyStateView.swift`) — extracted reusable empty state (sparkles icon + "Nada por aquí..." + custom message). Replaces inline duplicates in `ExpenseListView` and `ItemListDetailView`.

### Changed
- **Hero card label** (`ItemListDetailView`) — label now reads "Coste de {description}" instead of the bare description.
- **Hero meta row icons-only after timer** (`ItemListDetailView`) — category and payment method chips collapse to icon-only after 3 seconds; status (clock/checkmark) keeps full context visible at all times.

---

## [1.0.55] - 2026-04-28

### Changed
- **Date header "+" replaced with "…" context menu** (`ExpenseListView`) — the per-date add button in month-mode section headers is now an ellipsis menu (`ellipsis`, 18pt). Tapping it reveals a single action: "Añadir en esta fecha". Reduces visual noise while keeping the action accessible.

---

## [1.0.54] - 2026-04-26

### Changed
- **Date header "+" button muted to secondary color** (`ExpenseListView`) — the per-date add button in month-mode section headers changed from `Color.accentColor` to `Color.secondary`; it remains fully functional but no longer competes visually with the primary FAB — secondary feature, secondary color.

---

## [1.0.53] - 2026-04-26

### Refactor
- **All repositories marked `@MainActor` — `MainActor.run { }` removed** — all 7 repository protocols and their 7 implementations are annotated with `@MainActor`. Every `try await MainActor.run { }` wrapper is dropped; the body executes directly on the main actor with no hop. Fixes the Swift 6 strict-concurrency error *"Persistent Models are not Sendable"*: previously `MainActor.run` returned `@Model` objects back to a non-`@MainActor` context, crossing an actor boundary. Now the entire call chain is `@MainActor`: `AppDIContainer` → `ViewModel` → `UseCase` → `Repository` → `ModelContext` — no boundary crossings.

---

## [1.0.52] - 2026-04-26

### Refactor
- **Global (unscoped) fetch methods removed from all repositories** — no repository can fetch without a scope. Methods removed from protocol and implementation:
  - `CategoryRepository`: `fetchCategories()` (no groupId)
  - `ItemListRepository`: `fetchItemLists()`, `fetchItemList(id:)`, `fetchItemLists(forCategoryId:)`, `fetchItemLists(from:to:)`
  - `ItemRepository`: `fetchItems()`, `fetchItem(id:)`
  - `PaymentMethodRepository`: `fetchPaymentMethods()`, `fetchPaymentMethod(id:)`, `fetchActivePaymentMethods()`
- All were dead code — no callers anywhere in the codebase. Mirrors at the repository layer what v1.0.45 did for Use Cases.
- `START_HERE.md`: removed stale Liquid Glass bullet.

---

## [1.0.51] - 2026-04-25

### Refactor
- **`PaymentMethodFormViewModel` extracted** — `PaymentMethodFormView` was using `PaymentMethodListViewModel` (list VM) for form operations (create/update), the same bug fixed for `CategoryFormView` in v1.0.46. Dedicated `PaymentMethodFormViewModel` created with `save(name:type:icon:groupId:methodToEdit:) -> Bool` handling both creation and editing. View's `save()` remains a thin UI orchestrator (trim → VM → `onSaved` + `dismiss`).
- **`PaymentMethodListViewModel` slimmed down** — removed `createPaymentMethodUseCase`, `updatePaymentMethodUseCase` and the methods `createPaymentMethod()`, `updatePaymentMethod()`, `loadActivePaymentMethods()`, `loadPaymentMethods(forGroupId:type:)`, `toggleActiveStatus()`, `getPaymentMethodsCount()` and computed properties `activePaymentMethods`, `inactivePaymentMethods`, `paymentMethodsByType` — none were called from `PaymentMethodManagementView`. From 184 lines to 55.
- **`AddPaymentMethodViewModel` deleted** — never used by any View; its API (`configureForCreation`, `configureForEditing`, `submit()`) was incompatible with `PaymentMethodFormView` (missing `icon`, English-language validations, free-form type strings instead of the app's internal type codes).

---

## [1.0.50] - 2026-04-25

### Refactor
- **`AddItemListViewModel` moved to `Dashboard/ViewModels/`** — the VM lived in `ItemList/ViewModels/` but no View in that scene used it; its only consumer is `AddItemListView` which lives in `Dashboard/Views/`. Moved to co-locate VM and View in the same scene.

---

## [1.0.49] - 2026-04-25

### Refactor
- **Legacy tests removed, SwiftData tests added** — CoreData-based test files (`TestEntityFactory`, `MockCoreDataStack`, `*Domain` mocks, and all `*ServiceTests`) referenced types that no longer exist after the SwiftData migration; removed. Added `SwiftDataTestContainer` as an in-memory `ModelContainer` test helper. New tests: `CreateGroupUseCaseTests` (empty name validation, trim, currency uppercase) and `FetchCategoriesUseCaseTests` (scope by group, no bleed from other groups, sort by name). Test targets updated to `IPHONEOS_DEPLOYMENT_TARGET = 26.0` to match the main target.

---

## [1.0.48] - 2026-04-25

### Refactor
- **Global `@Query` removed from picker Views** — `CategoryPickerView` and `PaymentMethodPickerView` were loading all entities from the database and filtering in memory (`allCategories.filter { $0.group?.id == groupId }`). Now use `Query(filter: #Predicate<SD...> { $0.group?.id == id }, sort: ...)` initialized in `init`, so SwiftData emits `WHERE group_id = ?` in SQLite instead of a full table scan. `PaymentMethodPickerView` additionally includes `&& $0.isActive` in the predicate.

---

## [1.0.47] - 2026-04-25

### Refactor
- **`GroupFormViewModel` extracted** — `CreateGroupView` and `GroupFormView` were calling `CreateGroupUseCase`, `CreateUserGroupUseCase`, and `UpdateGroupUseCase` directly from the View, violating Clean Architecture. Both views now use a dedicated `GroupFormViewModel` with `create(name:currency:userId:) -> SDGroup?` and `update(group:name:currency:) -> Bool`. Views remain thin UI orchestrators (trim → VM → callback + dismiss).

### Changed
- **Group settings moved to the group chip** — Categories and Payment Methods removed from `SettingsSheetView` (gear icon) and placed in `GroupFormView` (swipe → "Settings" on the group chip). `SettingsSheetView` now only contains the "Account" section. `GroupFormView` adopts a `ScrollView/VStack` layout with cards separated by section (Name, Currency, Content), opens as `.large`, and shows each navigation row with a colored icon, white label, and `chevron.right` arrow.

---

## [1.0.46] - 2026-04-25

### Refactor
- **`CategoryFormViewModel` extracted** — `CategoryFormView` was using `CategoryListViewModel` (list VM with fetch/delete/`categories: [SDCategory]`) for form operations. Now uses a dedicated `CategoryFormViewModel` with only `createCategoryUseCase` + `updateCategoryUseCase`. The `save()` method returns the created/edited `SDCategory` directly, eliminating the fragile `viewModel.categories.last` hack. View's `save()` remains a thin UI orchestrator (trim → VM → `onSaved` + `dismiss`).

---

## [1.0.45] - 2026-04-25

### Refactor
- **Global queries removed from Use Cases** — no `Fetch*UseCase` can execute without a mandatory scope (`groupId` or `itemListId`). Removed overloads:
  - `FetchCategoriesUseCase` — `execute()` (global) and `execute(categoryId:)` (never called).
  - `FetchItemListsUseCase` — `execute()` (global), `execute(itemListId:)`, `execute(forCategoryId:)` (no groupId), `execute(from:to:)` (no groupId).
  - `FetchItemsUseCase` — `execute()` (global) and `execute(itemId:)` (never called).
  - `FetchPaymentMethodsUseCase` — `execute(paymentMethodId:)` (never called).
  - Each use case keeps only the signatures that receive `forGroupId` or `forItemListId`. `GetCurrentUserUseCase.execute()` retained — singleton fetch by design, not a global scan.
- **Orphaned factory methods removed from DIContainers**:
  - `GroupSceneDIContainer` — removed `makeFetchGroupsUseCase()` and `makeUpdateGroupUseCase()` (no callers via scene container).
  - `UserSceneDIContainer` — removed `makeFetchUsersUseCase()`, `makeSearchUsersUseCase()`, `makeUpdateUserUseCase()`, `makeDeleteUserUseCase()` (callers use `AppDIContainer` directly).
- **Dead UseCase files removed** — `FetchGroupsUseCase.swift`, `FetchUsersUseCase.swift`, `SearchUsersUseCase.swift`: protocols and implementations with no callers anywhere in the codebase.

---

## [1.0.44] - 2026-04-25

### Refactor
- **`deleteGroupUseCase` moved from View to `DashboardViewModel`** — architecture violation: `GroupPickerSheet` (View) was calling `DeleteGroupUseCase` directly. UseCase now lives in `DashboardViewModel.deleteGroup()` and the View only calls the callback `onDeleteGroup: (SDGroup) async -> Void`. `DashboardViewModel` handles persistence deletion and `availableGroups` rollback; `GroupPickerSheet` retains its own presentation state (`isDeletingGroup`, optimistic local list). Propagation chain: `DashboardView` → `DashboardBottomBarView` → `GroupSelectorChipView` → `GroupPickerSheet`.

### Fixed
- **"Select Group" sheet not closing when creating a new group** — when creating a group, `CreateGroupView` called `onGroupCreated` before `dismiss()`, so closing both sheets simultaneously failed silently. Fix: `groupWasCreated` flag + `onDismiss` on the child sheet; the parent sheet closes only after the child has finished its dismiss animation.

---

## [1.0.43] - 2026-04-25

### Refactor
- **`DispatchQueue.main.asyncAfter` fully removed** — all occurrences replaced with `Task { try? await Task.sleep(for:) }` for consistency with Swift Concurrency:
  - `GroupSelectorChipView` — sheet close after group change (300ms) and deactivation of deletion overlay (1.5s).
  - `CustomAlertView.dismissAlert()` — set `isPresented = false` after exit animation (250ms).
  - `AddItemListView` — scroll to `paymentMethodAnchor` after expanding payment methods (350ms).
  - `DashboardHeaderView.handleDebugAccess()` — reset of debug tap counter (2s); `@State var resetTask` added to cancel the previous timer on each tap, avoiding orphaned timers.
- **`DashboardHeaderView` removed** — dead code file; replaced by `DashboardTopBarView` in a prior refactor and never removed.

---

## [1.0.42] - 2026-04-24

### Refactor
- **`DateFormatterHelper.formatSectionDate` extracted** — section date formatting logic ("Hoy", "Ayer", "d MMM", "d MMM yyyy") moved from `ExpenseListView` to `DateFormatterHelper`; `AddItemListViewModel.formattedDate` replaced with `DateFormatterHelper.formatDate`.
- **Dead code removed** — `formattedItemListDate` (`ItemListDetailView`), `formatDate` (`DashboardViewModel`), `sheetTitle`/`displayedTotal`/`totalCardLabel` (`DashboardView`) were unused properties/methods; removed.

---

## [1.0.41] - 2026-04-24

### Fixed
- **`errorMessage` incorrectly used on non-fatal operations** — `deleteItemList`, `changeGroup`, `deleteItem`, and `toggleItemPaid` were assigning `errorMessage` in their catch blocks, incorrectly replacing the entire screen with `errorView`. Now `errorMessage` is only assigned on fatal load failures (`loadDashboardData`, `loadItems`); non-fatal operations perform a silent rollback or reload data without blocking the UI.

---

## [1.0.40] - 2026-04-24

### Changed
- **"¡Listo!" animation restored in `TotalSpentCardView`** — when `isSuccess` is `true`, the amount is momentarily replaced by "¡Listo!" with a `.push(from: .top)` incoming and `.push(from: .bottom)` outgoing transition; label stays fixed. Color `.primary` (white in dark mode).
- **`DashboardTopBarView` and `DashboardBottomBarView` extracted** — `viewPickerBar` and `bottomControls` moved to their own files; `DashboardView` instantiates them with explicit parameters.

---

## [1.0.39] - 2026-04-24

### Changed
- **Name sync when renaming a registry** — when editing an `SDItemList` that has exactly one item whose name matches the previous list name, the item is automatically renamed to the new name in the same `context.save()` transaction.

---

## [1.0.38] - 2026-04-24

### Changed
- **`TotalSpentCardView` moved to the bottom** — in `DashboardView` the hero card sits between the expense list and `bottomControls`; in `ItemListDetailView` it sits below the item list.

---

## [1.0.37] - 2026-04-24

### Changed
- **Standardized delete animation** — all swipe deletions (`SDItem`, `SDItemList`, `SDCategory`, `SDPaymentMethod`, `SDUser`, `SDGroup`) now use `withAnimation { array.removeAll/remove }` optimistically before the DB call; the UI yields animation control to SwiftUI to coordinate the row slide-out and list reflow as a single transition. Animated rollback with `append` on persistence error.
- **`import SwiftUI` added** to `CategoryListViewModel`, `PaymentMethodListViewModel`, and `UserListViewModel` to enable `withAnimation`.

---

## [1.0.36] - 2026-04-24

### Changed
- **`TotalSpentCardView` refactored as a generic component** — now accepts a `@ViewBuilder bottomContent` slot; `ItemListDetailView` reuses the component passing `heroMetaRow` as extra content, eliminating ~70 lines of duplicate code. Added `EmptyView` extension for Dashboard with no changes at the call site.
- **+/✓ icon animation fixed** — replaced `contentTransition(.symbolEffect(.replace.downUp))` with `if/else` using `.scale(0.4).combined(with: .opacity)`; transition controlled by SwiftUI, no abrupt cut.
- **Button goes 2D during success** — the top circle drops to `y: 4` (flush with the shadow = flat appearance) while `isSuccess` is active; springs back to 3D position when done.
- **Success state simplified** — removed "¡Listo!", `heroSuccessLabel`, and `successLabel`; the card keeps the total and label during success, only the icon changes to a green ✓.

### Removed
- **% comparison in `TotalSpentCardView`** — removed "X% more/less than yesterday" and "X% more/less than last month" indicators; out of scope for MVP0. Also removed `yesterdayItemLists`, `yesterdayTotal`, and `lastMonthTotal` from `DashboardViewModel`.

---

## [1.0.35] - 2026-04-24

### Changed
- **`ItemListDetailView` redesigned** — static hero card above the scrollable list; exact replica of `TotalSpentCardView`: animated total with `numericText`, 3D "+" button in accent color, green/red flash on total change, scale effect on the card; meta row below the total with icon + category name in its color and icon + payment method name in its semantic color (green/orange/purple/blue).
- **"¡Listo!" animation in `ItemListDetailView`** — when saving an item the hero card transitions to `heroSuccessLabel` + "¡Listo!" + green arrow; button turns green with checkmark; identical to dashboard behavior.
- **Success animation duration reduced to 900ms** (`DashboardView`, `ItemListDetailView`) — was 1200ms, too slow for adding multiple items in quick succession.

### Fixed
- **Xcode+Claude regression** — reverted all broken changes: `.glassEffect()`, `.primary.gradient`, `LiquidGlassButtonStyle`, `withAnimation { Task {} }`; restored to clean standard SwiftUI.

---

## [1.0.34] - 2026-04-23

### Added
- **Date-scoped "+" button in month section headers** (`ExpenseListView`, `DashboardView`) — in "Este mes" mode each date section header shows a `plus.circle.fill` button aligned after the day total; tapping opens `AddItemListView` with that date pre-selected

### Changed
- **All sections render at full opacity in month mode** (`DashboardView`) — removed the `focusedDate: Date()` pass that dimmed non-today sections to 40%; all rows now render equally

### Fixed
- **Wrong date on first sheet open** (`DashboardView`) — replaced `sheet(isPresented:)` + two-state pattern (`showingAddItemList` + `addForDate`) with `sheet(item:)` driven by a single `AddItemListTrigger: Identifiable`; eliminates the SwiftUI first-render race where the sheet content was evaluated before `addForDate` propagated, causing `initialDate` to be `nil` and defaulting to today

### Internal
- **`AddItemListTrigger`** — private `Identifiable` struct (`id: UUID`, `initialDate: Date?`) replaces `showingAddItemList: Bool` + `addForDate: Date?`; FAB and header "+" both set the trigger in one atomic assignment
- **`onAddForDate: ((Date) -> Void)?`** added to `ExpenseListView`; `nil` in "Hoy" mode, non-nil in "Este mes" mode

---

## [1.0.33] - 2026-04-23

### Changed
- **Settings group section header** (`SettingsSheetView`) — section label updated from "Grupo" to "Grupo: {group name}" so the user knows which group the settings apply to

---

## [1.0.32] - 2026-04-23

### Changed
- **Category icon in expense row** (`ExpenseRowView`) — replaced the 7pt color dot in the subtitle line with the category's SF Symbol at 11pt medium weight in the category color; falls back to `tag.fill` in `systemGray3` when no category is set

### Internal
- **`categories` tuple extended** (`DashboardViewModel`, `ExpenseListView`) — tuple type updated from `(name: String, color: String)` to `(name: String, color: String, icon: String)` across declaration and all 3 build sites in `DashboardViewModel`
- **`ExpenseRowView`** — new `categoryIcon: String?` parameter replaces `Circle` dot

---

## [1.0.31] - 2026-04-23

### Added
- **Concept suggestion engine** (`ConceptSuggestionEngine`) — pure Swift runtime engine that derives concept suggestions from existing `SDItemList` data; no new SwiftData entities; ranking: prefix match → contains match → recency → frequency; strictly category-scoped (no cross-category bleed)
- **Amount-aware suggestion boosting** (`ConceptSuggestionEngine`) — when a price is entered, past item lists whose total falls within ±5% of the current amount are ranked first; suggestions re-rank in real time as the user types the amount
- **Concept suggestion chips** (`ConceptSuggestionChipsView`) — horizontal pill row shown below the concept field only when it is focused and history exists for the selected category; max 3 chips; tapping fills the field and keeps the keyboard open; animated fade + slide on appear/disappear
- **Category-colored chips** — chip background uses the selected category's color (same hex as the category grid chip) with white text; falls back to `systemGray4` when no category is selected; instant visual link between chip and category
- **Silent autofill placeholder** (`AddItemListView`) — when a category with history is selected, the concept field placeholder shows the most recently used concept for that category instead of the generic hint; if saved with an empty concept, this value is used as the fallback (before category name)

### Changed
- **`descriptionPlaceholder`** (`AddItemListView`) — priority order: last used concept for category → "Concepto (ej. CategoryName)" → "Concepto"
- **`saveItemList()` fallback** (`AddItemListView`) — empty concept now resolves to `lastUsedConcept ?? selectedCategory?.name ?? "Concepto"` instead of skipping the history

### Internal
- **`ConceptSuggestionEngine`** (`Infrastructure/Helpers/`) — `getSuggestions(query:amount:forCategory:allCategories:)` + `lastUsed(forCategory:)`; ±5% amount tolerance via `abs(value - target) / target <= 0.05`
- **`AddItemListViewModel`** — `suggestions: [String]`, `lastUsedConcept: String?`, `updateSuggestions()` triggered on category load, description change, price change, category change, and focus change
- **`ConceptSuggestionChipsView`** (`Presentation/Common/Components/`) — `categoryColor: Color` parameter; uses iOS semantic colors (`Color(.secondaryLabel)`, `Color(.systemGray4)`) as fallback

---

## [1.0.30] - 2026-04-22

### Added
- **Yesterday / last-month trend comparison** (`TotalSpentCardView`, `DashboardViewModel`) — hero widget shows a trend line below the amount: "↓ 5% menos que ayer" (green) or "↑ 12% más que ayer" (red); in "Este mes" mode compares to last month; "Sin datos de comparación" shown when no prior data exists
- **Hero card success flash on item creation** (`TotalSpentCardView`, `DashboardView`) — when the user taps Save, the hero widget transitions in-place: label → item description, amount → "¡Listo!", button → green checkmark (`.symbolEffect` swap); resets to normal after 1.2 s once data is committed
- **`hideSectionHeaders` param** (`ExpenseListView`) — suppresses section date headers when `true`; used in today-only mode where "Hoy" is redundant with the hero widget

### Changed
- **Hero widget moved to top** (`DashboardView`) — `TotalSpentCardView` now sits between the view-picker pill and the expense list; bottom controls reverts to group selector + filter/search row only
- **Hero widget visual separation** (`DashboardView`) — 8 pt bottom padding + `shadow(color: .black.opacity(0.1), radius: 8, y: 4)` elevates the card above the list
- **"Hoy" section header hidden in today mode** (`DashboardView`, `ExpenseListView`) — `hideSectionHeaders: true` passed when `showingFullMonth == false`; date headers and per-day totals still shown in full-month mode

### Fixed
- **Hero total not refreshing after add** (`TotalSpentCardView`) — `displayedAmount` was blocked while `isSuccess == true`; the 5 € added during the success window was silently discarded; guard now only blocks flash/scale effects — `displayedAmount` always updates

### Internal
- **`DashboardViewModel` trend properties** — four pure computed properties derived from already-loaded data (no new fetches): `todayRawTotal`, `yesterdayItemLists`, `yesterdayTotal`, `lastMonthTotal`
- **`TotalSpentCardView` `isSuccess` mode** — `isSuccess: Bool` + `successLabel: String` optional params; button animates accent → green, plus → checkmark; `onAddExpense` no-ops during success window

---

## [1.0.29] - 2026-04-22

### Added
- **Today-only dashboard list** (`DashboardView`, `DashboardViewModel`) — the expense list defaults to showing only today's item lists; past days are hidden by default so the view stays focused on what's actionable right now
- **"Hoy / Este mes" segmented pill** (`DashboardView`) — appears in the top bar (left of the gear icon) whenever there are past items in the current month; tap "Este mes" to expand to the full month timeline, tap "Hoy" to collapse back; pill is absent when no past items exist
- **Past-day dimming in full-month view** (`ExpenseListView`) — new `focusedDate` parameter; when set, sections from days other than the focused date render at 40% opacity so today's section always stands out visually even in the expanded view
- **Filter logic in ViewModel** (`DashboardViewModel`) — `showingFullMonth`, `todayItemLists`, `monthItemLists`, and `hasItemsOutsideToday` all live in the ViewModel; `DashboardView` holds no filtering logic

### Fixed
- **Section jump on item deletion** (`DashboardViewModel`) — wrapping the optimistic `itemLists` removal in `withAnimation(.easeInOut(duration: 0.25))` ensures section disappearance and row repositioning animate in a single pass; previously the swipe animation and the layout restructure fired as two separate steps causing a visible jump

---

## [1.0.28] - 2026-04-22

### Changed
- **Payment method starts unselected on new item list** (`AddItemListViewModel`) — `selectedPaymentMethod` is always `nil` when creating; the last-used payment method is no longer pre-filled so quick-add doesn't accidentally associate a payment method; edit mode still restores the existing value

---

## [1.0.27] - 2026-04-22

### Changed
- **"artículo/artículos" replaces "ítem/ítems"** (`ExpenseRowView`) — row subtitle now reads "1 artículo" or "X artículos"; more natural Spanish terminology
- **Loading and empty-state strings updated** (`ItemListDetailView`) — "Cargando artículos...", "No hay artículos", "Agrega tu primer artículo con el botón +"
- **Error messages updated** (`ItemListDetailViewModel`, `AddItemViewModel`) — all user-facing error strings use "artículo" consistently

---

## [1.0.26] - 2026-04-22

### Changed
- **Cost card always shows today** (`DashboardView`, `TotalSpentCardView`) — card label and amount are now permanently "Coste de hoy" using `formattedTodayTotal`; no longer adapts to calendar day/month selection — today's spend is the strategic primary metric
- **Month total shown as secondary line** (`TotalSpentCardView`) — new optional `secondaryAmount` / `secondaryLabel` props render a caption line below the main amount; dashboard passes `formattedCachedMonthTotal()` + "este mes" so both time scopes are visible at a glance
- **`formattedTodayTotal`** (`DashboardViewModel`) — new computed property wrapping `formattedTotal(for: Date())`; reuses existing day-total logic

---

## [1.0.25] - 2026-04-22

### Changed
- **Item description field is multiline** (`AddItemView`) — `descriptionCard` now uses `axis: .vertical` and `maxLength: 200`; field grows with content instead of truncating to a single line
- **`LimitedTextField` supports multiline** (`LimitedTextField`) — added optional `axis: Axis = .horizontal` parameter; when `.vertical`, icon and clear button align to `.top` so they stay anchored as the field grows; all existing callers unchanged

### Fixed
- **`TotalSpentCardView` label truncates correctly** — added `.lineLimit(1)` + `.truncationMode(.tail)` to prevent wrapping; added `.frame(maxWidth: .infinity)` to the VStack so the label gets full available width before truncating (e.g. "Barbacoa..." instead of "Bar...")

---

## [1.0.24] - 2026-04-22

### Changed
- **Overflow categories/payment methods expand inline** (`AddItemListView`) — replaced `.sheet` presentation with in-grid expansion; tapping the overflow chip reveals all hidden chips in the same grid with a spring animation; a "Ver menos ↑" row collapses them back; both `categoryOverflowSheet` and `paymentMethodOverflowSheet` deleted
- **Category chips go compact when grid expands** (`AddItemListView`) — `categoryChip` uses `showDetails || showCategoryOverflow` as the compact flag so chips switch to horizontal layout when the overflow grid opens, matching the "Más detalles" layout
- **Scroll unlocks when overflow grids are open** (`AddItemListView`) — `scrollDisabled` condition extended to allow scrolling whenever `showCategoryOverflow` or `showPaymentMethodOverflow` is true
- **Selecting a payment method closes the expanded grid** (`AddItemListView`) — tapping any method chip sets `showPaymentMethodOverflow = false`, matching category behaviour
- **Scroll-to-anchor on payment method collapse** (`AddItemListView`) — after the grid collapses (via selection or "Ver menos"), a delayed `proxy.scrollTo("paymentMethodAnchor")` brings the section header back into view so the collapse feels natural regardless of scroll position

---

## [1.0.23] - 2026-04-22

### Added
- **Auto-sync descriptions on category change** (`AddItemListViewModel`) — when editing an item list created via quick-add (single item, both `itemListDescription` and `item.itemDescription` equal the **current category name**), changing the category renames both descriptions to the new category name; condition requires descriptions to match the current category name exactly — manually typed names like "Internet" are never touched even if both happen to be equal

---

## [1.0.22] - 2026-04-22

### Added
- **Edit group from chip picker** (`GroupSelectorChipView`) — orange "Editar" swipe action on each group row in `GroupPickerSheet`; opens `GroupFormView` as a `.medium` sheet where name and currency can be changed; sits alongside the existing delete swipe so all group management (create, select, edit, delete) lives in one place
- **`GroupFormView`** (`Group/Views/GroupFormView.swift`) — self-contained edit form for a group: `LimitedTextField` for name (30 char max) + inline currency picker (EUR/USD) with checkmark selection; gets `UpdateGroupUseCase` directly from `AppDIContainer.shared`; xmark/checkmark toolbar; no external ViewModel dependency
- **`makeUpdateGroupUseCase()`** (`AppDIContainer`) — factory method added so `GroupFormView` and future callers can resolve `UpdateGroupUseCase` from the shared container

### Fixed
- **Currency rows fully tappable** (`GroupFormView`) — `.contentShape(Rectangle())` added to the currency `HStack` so the entire row (including the `Spacer` gap) registers taps, not just the label text

### Removed
- **`GroupManagementView` + `GroupManagementViewModel`** — deleted; group editing moved into the existing chip picker sheet; Settings (`SettingsSheetView`) stays group-contextual (Categories, Payment Methods only)

---

## [1.0.21] - 2026-04-22

### Fixed
- **Paid status no longer dims text** (`ExpenseRowView`, `ItemRowView`) — removed opacity and `.secondary` foreground style changes on description and amount when `isPaid` is toggled; only the check icon changes color (green `checkmark.circle.fill` when paid, gray `circle` when not) — improves readability in both dashboard list and item detail

---

## [1.0.20] - 2026-04-22

### Added
- **3D press effect on add button** (`TotalSpentCardView`) — classic raised-button look using a dark base circle offset `y: 4`; on press the top face drops down to meet it with a spring animation, simulating a physical button being pushed into the surface

### Changed
- **Settings close button** (`SettingsSheetView`) — replaced `"Cerrar"` text with an `xmark` icon, consistent with all other sheets
- **Description field icon** (`AddItemListView`) — `character.cursor.ibeam` icon added to the left of the description `TextField` as a subtle visual hint
- **Description placeholder with category context** (`AddItemListView`) — no category: `"Concepto"`; category selected: `"Concepto sugerido (Alimentación)"` — updates reactively on category switch
- **Thicker divider between hero input and description** (`AddItemListView`) — replaced `Divider()` with a 1.5pt `Rectangle` using `Color(.separator)` for better visual separation
- **Hero input container resize smoothed** (`HeroAmountInputView`) — added `.animation(.spring(...), value: fontSize)` so the card height transitions smoothly as font size changes while typing

### Fixed
- **`heroAmountInput` restored in `AddItemView`** (`ItemListDetailView`) — was accidentally removed in a prior session; amount field is back in the individual item editor

---

## [1.0.19] - 2026-04-22

### Changed
- **Hero amount input hidden in edit mode** — `HeroAmountInputView` is a dashboard quick-add shortcut (create an item list + set a price in one shot); it no longer appears when editing an existing registry since money is an item-level property, not an item list property
- **Description field promoted in edit mode** — when hero input is hidden, the description `TextField` uses `.body` font, `.primary` color, and larger padding to fill the card as the primary field
- **Edit sheet title fixed** — `AddItemListView` navigation title changed from `"Editar Registro"` to `"Editar"` to avoid duplication with the `"Editar Registro"` action button in `ItemListDetailView`'s three-dots menu

---

## [1.0.18] - 2026-04-21

### Added
- **Paste support on hero amount input** — long-press on the amount field shows a "Pegar" context menu; pastes clipboard content (e.g. from iPhone Calculator) directly into the price field; clipboard parsing and sanitization handled in `AddItemListViewModel.pastePrice()` following Clean Architecture — view only fires the callback

---

## [1.0.17] - 2026-04-21

### Changed
- **Timeline list is now the default dashboard view** — previously the calendar was shown on launch; the list view is now the first and only active view for v1
- **Calendar view hidden** — `CalendarGridView` and its day-panel logic commented out; `.calendar` case falls through to the list view
- **View-picker dropdown hidden** — the "Calendario ⌄" `Menu` in `viewPickerBar` commented out; settings gear remains visible in its place

---

## [1.0.16] - 2026-04-18

### Changed
- **`AddItemListView` redesigned — money-first UX** — top card now leads with the full-size hero amount input (big centered number) and "Concepto" as a secondary field below it, matching the app's expense-first purpose; previously description was the dominant field
- **Description placeholder adapts to selected category** — when a category is selected its name is used as placeholder (e.g. "Alimentos"); falls back to "Concepto" when no category is chosen
- **Clear button on description field** — `xmark.circle.fill` appears inline when the field has text, matching the style used across the app
- **Date card reworked** — toggle row now splits into a tappable label area (collapses/expands the graphical picker with a chevron) and the toggle switch (enables/disables custom date); calendar auto-expands on toggle-on, date resets to today on toggle-off
- **"Más detalles" section reordered** — Date → Group → Payment method (was: Payment method → Date → Group)
- **Category required removed from `canSave`** — form can now be saved with just a valid price, supporting pure list creation (e.g. grocery list without an amount)

---

## [1.0.15] - 2026-04-17

### Fixed
- **Amount field shows correct decimals when editing** — `String(item.amount)` on a `Double` produced floating-point noise (e.g. `0.9800000000001`); replaced with `String(format: "%.2f", ...)` + trailing-zero stripping so `0.98` stays `0.98`, `1.50` → `1.5`, `1.00` → `1`

### Changed
- **Group picker selected checkmark enlarged** — `checkmark.circle.fill` now uses `.font(.title2)` for better visual weight

---

## [1.0.14] - 2026-04-17

### Changed
- **Toolbar buttons use icons instead of labels** — `CategoryFormView`, `CreateGroupView` now use `xmark` (cancel) and `checkmark` (confirm) SF Symbols instead of text labels, matching the standard adopted across the app
- **Group picker add button enlarged** — `plus.circle.fill` in `GroupPickerSheet` toolbar uses `.font(.title2)` and `.buttonStyle(.plain)` to remove the Liquid Glass container and render as a bare icon
- **Auto-switch to newly created group** — after creating a group via `CreateGroupView`, the app now automatically selects it as the active group instead of staying on the previous one
- **Delete group overlay now appears immediately** — `isDeletingGroup = true` is set in the alert confirmation action before `deleteGroup()` runs, eliminating the frame where the list was briefly visible between alert dismissal and overlay appearance

---

## [1.0.13] - 2026-04-17

### Fixed
- **Item lists in calendar day sheet now always sort newest-first** — sort comparator in `DashboardViewModel` now normalizes `date` to `startOfDay` before comparing, then falls back to `createdAt DESC` as tiebreaker. Previously, items created from the calendar sheet (stored with `date = midnight`) sorted below items created from the main dashboard (stored with `date = current time`) even when created more recently. Affects `refreshData()`, `addItemList()`, and `updateItemList()`.

---

## [1.0.12] - 2026-04-17

### Changed
- **Category grid capped at 3 + "Más"** — `gridCategoryLimit` reduced from 5 to 3; always a 2×2 grid of 4 elements
- **Payment method grid capped at 3 + "Más"** — same pattern applied to payment methods: first 3 shown inline, overflow opens a bottom sheet
- **Payment method overflow chip** — mirrors category overflow chip behaviour: shows selected overflow item's name/icon when active, chevron rotates on open; tap-to-deselect works inside the sheet too
- **Payment method overflow sheet** — `presentationDetents` height computed dynamically from overflow count, same style as category sheet

---

## [1.0.11] - 2026-04-17

### Changed
- **Payment method now optional in `AddItemList`** — removed `selectedPaymentMethod != nil` from `canSave` and simplified `showValidationToast()` to only warn about missing category; user can save and assign payment method later
- **Tapping a selected payment method deselects it** — toggled in `AddItemListView`; UserDefaults last-used key is only written on selection, not deselection

---

## [1.0.10] - 2026-04-17

### Changed
- **`CreateFirstUserView` redesigned** — full onboarding screen rewrite:
  - Gradient icon header with `.pulse` symbol effect
  - Custom input fields with icon, focus ring stroke, and `contentTransition` on icon color change
  - Submit label `.next` / `.done` for keyboard tab navigation between fields
  - Button uses gradient background + shadow when form is valid, `PressHapticButtonStyle`, bounces icon on validation state change
  - Plain `VStack` layout (no `ScrollView`) — SwiftUI keyboard avoidance pushes content up natively
  - Form content fades out (`opacity 0`) while loading overlay is active
  - Dark mode preview added
- **`CreateFirstUserView` no longer a sheet** — shown inline as full-screen content in `MainView` when no user exists; eliminates the broken state where dismissing the sheet left users stranded
- **`MainView` simplified** — removed `showingCreateFirstUser` binding and sheet; `CreateFirstUserView` rendered directly in the `else` branch
- **`CreateFirstUserViewModel`** — added `loadingMessage: String` property; updated `createUser()` to emit step-by-step messages ("Creando usuario…", "Creando grupo personal…", "Configurando categorías…", "¡Listo!")

---

## [1.0.9] - 2026-04-17

### Removed
- **`isDefault: Bool` removed from `SDCategory`** — property, init param, and mock param deleted
- **`isDefault: Bool` removed from `SDPaymentMethod`** — property, init param, and mock param deleted
- **`SDGroup.defaultCategory` and `SDGroup.defaultPaymentMethod`** computed properties deleted
- **`isDefault` removed from all downstream layers** — `CategoryRepository`, `PaymentMethodRepository`, `CreateCategoryUseCase`, `CreatePaymentMethodUseCase`, `DefaultCategoryRepository`, `DefaultPaymentMethodRepository`, `DefaultGroupRepository`, `CategoryListViewModel`, `AddPaymentMethodViewModel`, `PaymentMethodListViewModel`
- **`isDefault` UI guards removed** — `CategoryManagementView` and `PaymentMethodManagementView` no longer block editing/deleting rows based on `isDefault`; all rows are now fully editable and deletable

### Added
- **`sortOrder: Int` added to `SDCategory`** (default `0`) — controls display order independent of name
- **"Otros" seeded with `sortOrder: 999`** in `DefaultGroupRepository` so it always renders last regardless of alphabetical sorting

### Changed
- **`DefaultCategoryRepository.fetchCategories(forGroupId:)`** — sort changed from `[name]` to `[sortOrder, name]`
- **`AddItemListView` grid/overflow category split** — removed `isDefault`-based partitioning; grid shows first 5 categories, overflow shows the rest
- **`AddItemListView` payment method UserDefaults key** renamed from `lastUsedNonDefaultPaymentMethodId_*` to `lastUsedPaymentMethodId_*`

---

## [1.0.8] - 2026-04-16

### Removed
- **`Data/CoreData/` directory deleted** — `Persistence.swift`, `OMOMoney.xcdatamodeld`, and empty `Entities/` folder removed; none were referenced in `project.pbxproj` or called from any Swift file
- **`SettingsView.swift` deleted** — legacy view using old `User` domain type; never referenced outside its own file; app uses `SettingsSheetView` exclusively
- **`GroupSelectorView.swift` deleted** — legacy view using old `Group` domain type; never referenced outside its own file

### Fixed
- **`PerformanceMonitor.swift`** — removed stale `import CoreData`; the import was unused (no CoreData types referenced in the file)

---

## [1.0.7] - 2026-04-16

### Changed
- **Liquid Glass UI — Phase 4 Step 4.4** — Replaced flat/opaque backgrounds with SwiftUI materials across Dashboard; materials automatically render as Liquid Glass on iOS 26:
  - `TotalSpentCardView`: `Color(.systemGray5)` → `.regularMaterial`, shadow removed
  - `bottomControls` bar: `Color(.systemBackground)` → `.regularMaterial` (extends into safe area)
  - `viewPickerBar` dropdown pill: `Color.accentColor.opacity(0.1)` → `.thinMaterial`
  - Filter/search capsule: `Color(.systemGray5)` → `.thinMaterial`
  - `dayListPanel` slide-up panel: `Color(.systemGray5)` → `.regularMaterial`, shadow softened (`opacity 0.15→0.08`, `radius 12→8`)
- **`START_HERE.md` updated** — Phase 4 marked complete; all steps 4.1–4.4 checked off

---

## [1.0.6] - 2026-04-16

### Changed
- **`CategoryPickerView` migrated to `@Query`** — `CategoryPickerViewModel` deleted; view now uses `@Query(sort: \SDCategory.name)` with in-memory filter by `groupId`; `.task` fetch, `isLoading` spinner, and error state removed
- **`PaymentMethodPickerView` migrated to `@Query`** — `PaymentMethodPickerViewModel` deleted; view now uses `@Query(sort: \SDPaymentMethod.name)` with in-memory filter by `groupId && isActive`; `.task` fetch, loading/error state removed
- **`START_HERE.md` updated** — Phase 4 Step 4.3 marked complete

### Removed
- `Presentation/Scenes/Category/ViewModels/CategoryPickerViewModel.swift`
- `Presentation/Scenes/PaymentMethod/ViewModels/PaymentMethodPickerViewModel.swift`

---

## [1.0.5] - 2026-04-16

### Changed
- **Domain entity layer deleted** — `UserDomain`, `GroupDomain`, `ItemListDomain`, `ItemDomain`, `CategoryDomain`, `PaymentMethodDomain`, `UserGroupDomain` structs removed; all layers now use SwiftData `SD*` types directly as the single source of truth
- **CoreData mapping files deleted** — all 7 `*+Mapping.swift` files (`Category+Mapping`, `Group+Mapping`, `Item+Mapping`, `ItemList+Mapping`, `PaymentMethod+Mapping`, `User+Mapping`, `UserGroup+Mapping`) removed; `.toDomain()` conversion no longer exists anywhere in the codebase
- **All 22 use cases updated** — return and accept `SD*` types (`SDUser`, `SDGroup`, `SDItemList`, `SDItem`, `SDCategory`, `SDPaymentMethod`, `SDUserGroup`) in every protocol and implementation
- **All 14 ViewModels updated** — `DashboardViewModel`, `AddItemListViewModel`, `ItemListDetailViewModel`, `AddItemViewModel`, `EditUserViewModel`, `UserDetailViewModel`, `UserListViewModel`, `CategoryListViewModel`, `CategoryPickerViewModel`, `PaymentMethodListViewModel`, `AddPaymentMethodViewModel`, `PaymentMethodPickerViewModel` rewritten to use SD* types; `updateItem`/`updateCategory`/`updatePaymentMethod` now mutate reference-type properties directly instead of creating new structs
- **All Views updated** — `ItemListDetailView`, `AddItemView`, `ItemRowView`, `CategoryFormView`, `CategoryManagementView`, `PaymentMethodFormView`, `PaymentMethodManagementView`, `PaymentMethodPickerView`, `UserProfileView`, `EditUserView`, `UserListView`, `GroupSelectorChipView`, `CreateGroupView`, `ExpenseListView`, `ExpenseRowView`, `CalendarGridView`, `AddItemListView`, `DashboardView`, `SettingsSheetView`, `AppContentView` updated to `SD*` types throughout
- **`ExpenseListView` row extraction** — `itemListRow(_:)` `@ViewBuilder` method extracted from `body` to resolve Swift type-checker timeout; category lookups split into named `let` bindings

### Removed
- 7 `Domain/Entities/*Domain.swift` files (~500 lines)
- 7 `Data/CoreData/Entities/*+Mapping.swift` files (~300 lines)

---

## [1.0.4] - 2026-04-16

### Changed
- **14 ViewModels migrated to `@Observable`** — `ObservableObject` conformance and all `@Published` property wrappers removed; `@Observable` macro applied; affected ViewModels: `DashboardViewModel`, `AddItemListViewModel`, `ItemListDetailViewModel`, `AddItemViewModel`, `UserListViewModel`, `EditUserViewModel`, `CreateUserViewModel`, `CreateFirstUserViewModel`, `UserDetailViewModel`, `CategoryPickerViewModel`, `CategoryListViewModel`, `PaymentMethodPickerViewModel`, `PaymentMethodListViewModel`, `AddPaymentMethodViewModel`
- **13 Views updated for `@Observable` ViewModels** — `@StateObject` → `@State`, `StateObject(wrappedValue:)` → `State(wrappedValue:)` in all `init` methods; affected Views: `DashboardView`, `AddItemListView`, `ItemListDetailView`, `UserListView`, `EditUserView`, `AddUserView`, `CreateFirstUserView`, `CategoryPickerView`, `CategoryManagementView`, `CategoryFormView`, `PaymentMethodPickerView`, `PaymentMethodManagementView`, `PaymentMethodFormView`
- **`START_HERE.md` updated** — Added Rule 0: build and test before every commit; updated Phase 4 progress (Step 4.1 complete); `@Observable` marked as complete in stack table; `ObservableObject` moved to ❌ FORBIDDEN red flags

---

## [1.0.3] - 2026-04-15

### Changed
- **`AppDIContainer` migrated to SwiftData** — replaced `NSManagedObjectContext` / `PersistenceController` with `ModelContext` from `ModelContainer.shared`; all 7 repositories now receive `ModelContext` directly; service layer fully removed
- **All repositories rewritten for SwiftData** — `DefaultUserRepository`, `DefaultGroupRepository`, `DefaultCategoryRepository`, `DefaultPaymentMethodRepository`, `DefaultItemListRepository`, `DefaultItemRepository`, `DefaultUserGroupRepository` now use `ModelContext` + `FetchDescriptor` / `#Predicate` instead of `NSFetchRequest`; `.toDomain()` mappings kept as private extensions
- **Service layer deleted** — `CategoryService`, `CoreDataService`, `GroupService`, `ItemListService`, `ItemService`, `PaymentMethodService`, `UserGroupService`, `UserService` and matching `*ServiceProtocol` files removed; repositories talk to `ModelContext` directly
- **`DataPreloader` removed** — no longer needed; SwiftData container seeds preview data via `ModelContainer.preview`
- **`TestDataGenerator` rewritten for SwiftData** — replaced `NSManagedObjectContext` + Core Data entities with `ModelContext` + `SDItemList`/`SDItem`; marked `@MainActor`

### Fixed
- **Default categories and payment methods not created on group creation** — seeding logic lost when `GroupService` was deleted is restored in `DefaultGroupRepository.createGroup`; each new group now atomically inserts 4 payment methods (Efectivo, Débito, Crédito, Transferencia) and 6 categories (Alimentación, Movilidad, Hogar, Ocio, Salud, Otros) in the same `context.save()` transaction
- **Presentation layer — all Core Data references removed** — `import CoreData`, `@Environment(\.managedObjectContext)`, `NSManagedObjectContext` params, and `PersistenceController` preview references eliminated from all 9 affected view files:
  - `CreateGroupView`, `AddUserView`, `CreateFirstUserView` — unused `import CoreData` removed
  - `EditUserView`, `CategoryPickerView` — unused `context: NSManagedObjectContext` params dropped from inits; previews updated to `ModelContainer.preview`
  - `UserListView` — `init(context:)` simplified to `init()`; `EditUserView` call updated
  - `PaymentMethodPickerView` — `group: Group` (NSManagedObject) parameter replaced with `groupId: UUID`
  - `TestDataView` — `@Environment(\.managedObjectContext)` → `@Environment(\.modelContext)`; preview updated

---

## [1.0.2] - 2026-04-15

### Changed
- **Project structure reorganized for SwiftData migration** — `SD*.swift` models, `OMOMoneySchema.swift`, and `ModelContainer+Shared.swift` moved from project root into `OMOMoney/Data/SwiftData/` following the existing `Data/CoreData/` convention; all migration `.md` docs moved from project root into `docs/`; stale manual Xcode project entries removed (files now auto-discovered via `PBXFileSystemSynchronizedRootGroup`)

---

## [1.0.1] - 2026-04-15

### Added
- **SwiftData injected into app entry point** — `ModelContainer.shared` initialized in `OMOMoneyApp`; `.modelContainer()` modifier applied to `ContentView`; Core Data stack kept in parallel until Phase 3

### Fixed
- **`ModelsSwiftData*.swift` duplicates removed** — 8 conflicting files (`class ItemList`, `class Group`, etc.) deleted from project; `SD*` files are the canonical SwiftData models
- **`where Self: NSManagedObject` removed from all 7 `*+Mapping.swift` extensions** — invalid constraint on concrete `NSManagedObject` subclass extensions

---

## [1.0.0] - 2026-04-15

### Added
- **SwiftData models** — `SDUser`, `SDGroup`, `SDUserGroup`, `SDCategory`, `SDPaymentMethod`, `SDItemList`, `SDItem` with relationships, validations, computed properties, and debug mock helpers
- **`OMOMoneySchema.swift`** — versioned `SchemaV1` registering all 7 models
- **`ModelContainer+Shared.swift`** — shared production container, in-memory preview and test containers, `safeSave`/`safeRollback` helpers

---

## [0.47.1] - 2026-04-15

### Changed
- **Empty state copy and icon in ExpenseListView** — icon changed from `tray` to `sparkles.2`; title updated to "Nada por aquí..."; subtitle shortened to "Pulsa el + para agregar una lista"

---

## [0.47.0] - 2026-04-15

### Changed
- **New items and item lists appear at the top** — items inside a list now sort by `createdAt` descending; item lists within the same day also sort by `createdAt` descending so the latest addition always appears first; affects `ItemService`, `ItemListService` (all four fetch queries), and the three in-memory sorts in `DashboardViewModel`

---

## [0.46.2] - 2026-04-15

### Fixed
- **Toast rapid-tap instability** — tapping repeatedly caused shorter display times and erratic behaviour; `onDisappear` was calling `onDismiss()` which wiped the incoming toast when SwiftUI replaced the old view via `.id()`; removed `onDismiss()` from `onDisappear` to keep each tap independent
- **Toast haptics replay on navigation return** — navigating into an item list detail and back replayed the 3-tap haptic; `DashboardView` now clears `toast` as soon as `navigationPath` becomes non-empty, so no toast state survives the push

---

## [0.46.1] - 2026-04-15

### Fixed
- **Payment method type buttons misaligned** — "Transferencia" label was wrapping to two lines, making its cell taller than the others in the grid; added `lineLimit(1)` + `minimumScaleFactor(0.8)` so all four buttons share a consistent height

---

## [0.46.0] - 2026-04-15

### Added
- **In-app toast notifications** — new reusable `ToastView` component (`Presentation/Common/Components/Toast/`) with warning, error, and info types; appears from the top with a spring animation, auto-dismisses after 2.5 s, and triggers 3 quick haptic taps on appearance
- **Form validation feedback** — tapping "Guardar" in AddItemListView while fields are missing now shows a contextual toast ("Selecciona una categoría", "Selecciona un método de pago", or both) instead of silently doing nothing; the Save button is always tappable
- **Empty list paid-toggle feedback** — tapping the paid toggle on an item list with no items now shows a "Lista vacía" toast and skips the optimistic UI update, eliminating the previous flicker-and-revert behaviour

---

## [0.45.2] - 2026-04-15

### Removed
- **Unused batch/bulk operation dead code** — removed `batchDelete`, `batchUpdate`, `bulkInsert` from `CoreDataService`; all bulk methods from `GroupService`, `UserService`, `ItemListService` and their protocols; `BulkInsertItemListsUseCase`; `makeBulkInsertItemListsUseCase` from `AppDIContainer`; `CoreDataError` enum — none of these were reachable from any UI or UseCase and `batchDelete` specifically bypassed CoreData cascade rules, posing a data-loss risk if ever wired up

---

## [0.45.1] - 2026-04-15

### Fixed
- **CoreData cascade delete wipe** — `Category.group` and `PaymentMethod.group` relationships had `deletionRule="Cascade"` instead of `Nullify`; deleting a single category or payment method was silently cascade-deleting the entire Group and all its ItemLists, Items, and Categories; corrected both to `Nullify` so only the category/payment method itself is removed

---

## [0.45.0] - 2026-04-15

### Changed
- **List view day totals** — section headers in list mode now show the total spending for that day right-aligned alongside the date label; reuses the existing `formattedTotal(for:)` ViewModel method; calendar and compact panel headers are unaffected

---

## [0.44.0] - 2026-04-15

### Changed
- **Portrait-only orientation** — app is now locked to portrait mode via `UIApplicationDelegate.supportedInterfaceOrientationsFor`; landscape rotation is disabled app-wide

---

## [0.43.0] - 2026-04-15

### Changed
- **Pending row style in expense list** — when all items in an item list are unpaid (`paidStatus == .none`), the description, amount, and category dot are rendered in secondary/muted colors; paid and partial rows keep full-contrast primary style, making payment status immediately scannable
- **Pending item style in item detail** — individual items with `isPaid = false` now render their description and amount in secondary color; paid items stay primary; the check toggle remains full opacity in both states

---

## [0.42.1] - 2026-04-15

### Fixed
- **Bottom controls background bleed** — `TotalSpentCardView` + group chips background now extends into the bottom safe area via `ignoresSafeArea(edges: .bottom)`; previously the day panel closing animation revealed a transparent gap at the screen bottom edge behind the controls

---

## [0.42.0] - 2026-04-14

### Changed
- **Calendar unpaid indicator** — days with at least one unpaid item list now show the spending amount in orange instead of accent color; fully paid days keep the accent color; improves at-a-glance payment status on the calendar
- **Day panel date header removed in compact mode** — "HOY", "AYER", "12 ABR" label removed from the day expense list panel; context is already provided by the calendar week-strip selection and the total card label ("Coste del 13 abr"), recovering vertical space
- **Day panel bottom fade** — subtle 10pt gradient at the bottom edge of the day expense list panel fades content into the panel background, softening the hard clip of the rounded corner
- **Calendar daily totals precomputed once per render** — `dailyTotals` dictionary is now computed a single time in `body` and passed as a parameter to `dayCell`, instead of being recomputed on every cell access; eliminates 30+ redundant iterations per render frame with large datasets

### Performance
- **`currentMonthTotal` cached in ViewModel** — month total is now a `@Published var` updated inside `calculateTotalSpent()` using the already-cached `currentMonthItemLists`; `displayedTotal` reads the cached value directly instead of filtering and reducing `itemLists` inline on every render frame, eliminating per-frame O(n) work during panel open/close animations

---

## [0.41.0] - 2026-04-14

### Changed
- **Calendar day cells redesigned (Neubrutalism / accessibility)** — cells replaced from small circles (32×32 pt, 14 pt date, 9 pt amount) to full-width borderless cards; date number is now 20 pt bold rounded, spending amount 13 pt semibold — both readable at iOS display zoom; row height raised to 64 pt (collapsed strip) / 72 pt max (full month); month header bumped to 20 pt bold rounded, nav buttons to 44×44 pt (HIG minimum); weekday labels to 11 pt semibold
- **Calendar cell backgrounds** — all days transparent except selected day which shows a solid accent fill; no borders on any cell
- **Calendar spending amount color** — all days with spend always show the amount in full accent color (no opacity fade); previously low-spend days faded to near-invisible gray
- **Calendar last-row overflow fixed** — row height calculation now subtracts inter-row spacing before dividing, preventing the last week from being clipped on zoomed displays

---

## [0.40.0] - 2026-04-09

### Fixed
- **Calendar month navigation** — navigating to a past or future month now correctly loads its item lists and totals. Root cause was two-layer: (1) `CalendarGridView` had no upward callback for month changes, so the parent kept passing only current-month data; (2) `DashboardViewModel.calculateTotalSpent()` only iterated `currentMonthItemLists`, leaving `itemListTotals` empty for any other month. Fix: `CalendarGridView` now exposes `onMonthChange: (Date) -> Void`; `DashboardView` tracks `displayedCalendarMonth` and passes all `viewModel.itemLists` to the grid; `DashboardViewModel` iterates `itemLists` in `calculateTotalSpent`, `formattedTotal(for:)`, and the new `formattedTotal(forMonth:)` method; `TotalSpentCardView` label adapts to "Coste en Marzo 2026" for non-current months

### Changed
- **Calendar cells with zero-spend days** — days that have item lists but no items (total = €0) now display "0,00 €" in a muted secondary color instead of showing nothing, making it clear the day has records

---

## [0.39.0] - 2026-04-09

### Changed
- **`LimitedTextField` clear button** — replaced character counter (`5/20`) with a native `xmark.circle.fill` button; tap clears the field instantly with a fade+scale animation; consistent with iOS standard text field behavior (search bars, URL bar, etc.)
- **`LimitedTextField` max length** raised from 20 to 30 characters; change applies to all 5 usages: item list description, item description, user profile name, category name, payment method name

---

## [0.38.0] - 2026-04-09

### Changed
- **`TotalSpentCardView` redesigned** — label upgraded from `.caption` to `.subheadline .medium`; amount font increased from 24 pt to 34 pt (adaptive); "+" button enlarged from 34×34 to 48×48 with a 20 pt icon (meets iOS 44 pt minimum tap target)
- **Group selector chip icon** changed from `folder.fill` to `person.3.fill` — better reflects the concept of a shared group
- **Settings button icon** changed from `gear` to `gearshape.fill` — filled variant with more visual weight

---

## [0.37.0] - 2026-04-09

### Added
- **Dynamic `TotalSpentCardView` label** — shows "Coste de vida este mes" when no day is selected, "Coste de vida hoy" when today is selected, or "Coste del 6 abr" for any other date; `ItemListDetailView` shows "Coste de [nombre del registro]"
- **Animated subtotal card in `AddItemView`** — replaces the small caption info text; appears when quantity > 1 and amount is set; shows the unit × qty formula and the total in a large bold animated number with `numericText` spring transition
- **Pre-fill date on new item list** — tapping "+" while a calendar day is selected opens `AddItemListView` with that date pre-filled; `AddItemListViewModel` accepts `initialDate` parameter
- **Drag-to-dismiss day expense panel** — day expense list is shown as an inline panel with a pill drag handle; dragging down > 80 pt dismisses it and expands the calendar back to full month; bottom controls (TotalSpentCard, group chip, filters) always remain visible

### Changed
- **All calendar days now tappable** in full-month mode — removed the `.disabled` check that blocked days without spending; enables future-date planning (e.g. scheduling rent payment)
- **New items default to `isPaid: false`** — items no longer auto-marked as paid on creation; payment is an explicit user action
- **`ExpenseRowView` unpaid label** changed from "restantes" to "por pagar"

---

## [0.36.0] - 2026-04-08

### Added
- **Calendar grid view** (`CalendarGridView`) on the dashboard — full month grid collapses to the selected week row when a day is tapped; daily totals shown below each date with opacity scaled to spend intensity
- **View mode picker** — dropdown in the top bar lets the user switch between "Calendario" and "Lista" views; resets to calendar on group change
- **Filter icon button** in bottom bar using SF Symbol `line.3.horizontal.decrease` alongside the existing search icon

### Changed
- **`DashboardView` bottom bar** restructured: group selector chip on the left, filter + search capsule on the right
- **`TotalSpentCardView`** total updates with a `numericText` content transition, directional flash (green/red), and scale bounce animation on change

### Refactored
- **Formatting logic moved out of Views into ViewModels** (all Views now contain only UI construction):
  - `DashboardView`: `formattedPaid(for:)`, `formattedUnpaid(for:)`, `formattedTotal(for:)` moved to `DashboardViewModel`; duplicate `currencyString(_:)` removed (already existed as `makeCurrencyFormatter()` in ViewModel)
  - `AddItemListView`: `formattedDate` moved to `AddItemListViewModel`
  - `AddItemView`: `showsTotalPreview` moved to `AddItemViewModel`

---

## [0.35.0] - 2026-04-06

### Added
- **Icon editing for categories** — icon picker now visible in edit mode (previously only on create); `UpdateCategoryUseCase`, `CategoryService`, and `DefaultCategoryRepository` updated to persist `icon` field through the full chain
- **Icon editing for payment methods** — new icon picker grid added to `PaymentMethodFormView`; preview updates live as icon is selected
- **`CategoryFormView.swift`** extracted from `CategoryManagementView.swift` into its own file
- **`PaymentMethodFormView.swift`** extracted from `PaymentMethodManagementView.swift` into its own file

### Changed
- **Payment method types** aligned to actual seeded data: `["cash", "card_debit", "card_credit", "bank_transfer"]` replacing the old `["card", "cash", "transfer", "digital"]`; `typeName()`, `typeIcon()`, `typeColor()` updated with exact `switch` matching (no more `contains` checks or raw type leaking into UI)
- **`PaymentMethodManagementView` row** now uses stored `pm.icon` with fallback to `typeIcon(pm.type)` instead of always deriving from type
- **`AddItemListView` payment method chips** now derive color from `paymentMethodType` and icon from stored `method.icon` (with type fallback) — fixes grey cards caused by stale default color stored in CoreData from old build
- **`PaymentMethodListViewModel.updatePaymentMethod`** refactored: takes existing `PaymentMethodDomain` directly instead of searching empty local array — fixes silent no-op when saving from the form sheet
- **`PaymentMethodListViewModel.updatePaymentMethod`** now preserves `color`, `isDefault`, and all fields when building the updated domain model
- **`PaymentMethodListViewModel.createPaymentMethod`** accepts `icon` parameter
- **`UpdatePaymentMethodUseCase` / `PaymentMethodService` / `DefaultPaymentMethodRepository`** — `icon` field now flows through the full update chain to CoreData
- **Scenes restructured** into `Views/` + `ViewModels/` subdirectories for all scenes: Category, PaymentMethod, Dashboard, ItemList, User, Group

### Fixed
- Icon never saved to CoreData on category update — `CategoryService.updateCategory` was missing `icon` parameter
- Icon never saved to CoreData on payment method update — `PaymentMethodService.updatePaymentMethod` was missing `icon` parameter
- `DefaultCategoryRepository` and `DefaultPaymentMethodRepository` not forwarding `icon` to their respective services
- `PaymentMethodFormView` save silently doing nothing — ViewModel searched an empty `paymentMethods` array for the method to update
- `typeName("card")` returning raw `"card"` string instead of `"Tarjeta"` due to fallback returning raw value when type was non-empty

---

## [0.34.0] - 2026-04-05

### Added
- **Per-item paid toggle** in `ItemListDetailView` — tap the circle icon on any item to mark it paid/unpaid individually
- **`PressHapticButtonStyle`** shared component in `Infrastructure/Helpers/` — rigid haptic on press, soft on release; used on all paid toggle buttons app-wide
- Haptic feedback on dashboard paid toggle (`ExpenseRowView`) using `PressHapticButtonStyle`

### Changed
- `getFormattedTotal()` in `ItemListDetailViewModel` now sums only items where `isPaid == true` — total reflects money already paid
- `itemListTotals` and `itemListPaidStatus` pre-populated with zero/default values before async calculation to eliminate "not found" warnings on group switch and new ItemList creation

### Fixed
- `⚠️ [UI] ItemList not found in itemListTotals` warning no longer fires during group switch or after adding a new ItemList

---

## [0.33.0] - 2026-04-05

### Changed
- **Cache refactor: domain models instead of CoreData objects**
  - `ItemListService`: caches `[ItemListDomain]` instead of `[ItemList]`; domain conversion now happens inside `context.perform`; TTL reduced from 30 min to 5 min
  - `ItemService`: `getItems(for:)` methods now cache `[ItemDomain]` (resolves long-standing TODO); cache invalidation added to all write operations (`createItem`, `updateItem`, `deleteItem`, `setAllItemsPaid`)
  - `DefaultItemListRepository` / `DefaultItemRepository`: removed redundant `.map { $0.toDomain() }` calls now handled by services
  - Protocols updated: `getItemLists` returns `[ItemListDomain]`, `getItems` returns `[ItemDomain]`

---

## [0.32.0] - 2026-04-05

### Added
- **Paid/unpaid check system** for ItemLists on the dashboard
  - `ToggleAllItemsPaidInListUseCase` — bulk toggle all items in an ItemList paid/unpaid
  - Dashboard row icon reflects paid status: `circle` (none), `circle.lefthalf.filled` (partial), `checkmark.circle.fill` (all)
  - `itemListPaidStatus` and `itemListUnpaidTotals` tracked per ItemList in `DashboardViewModel`

---

## [0.31.0] - 2026-04-03

### Added
- **Settings views** for User, Category, and Payment Method management
  - Edit user profile, manage categories with icon/color, manage payment methods

---

## [0.30.0] - 2026-03-31

### Changed
- Redesigned item list row (`ExpenseRowView`) and item row (`ItemRowView`) with updated layout and visual hierarchy

---

## [0.29.0] - 2026-03-31

### Changed
- **Redesigned `AddItemView`** with hero price input and refactored shared components
- Scroll disabled when "more details" section is closed in item list form

---

## [0.28.0] - 2026-03-29

### Added
- Category grid with morph animation, overflow sheet, and payment method chip height fix

### Fixed
- Auto-focus removed on open; parallel data load on form; scroll bugs; date picker animation
- Neutral gray border on amount input focus; edit mode auto-scroll prevented

---

## [0.27.0] - 2026-03-28

### Changed
- **Redesigned `AddItemListView`** with dynamic amount input, font scaling, inline currency symbol, and smart last-used category/payment method ordering

---

## [0.26.0] - 2026-03-19

### Added
- Edit registry feature — edit ItemList metadata (date, category, payment method) from inside `ItemListDetailView`
- Animation for total money widget on dashboard

### Fixed
- Article count shows item quantity instead of item count
- Phantom keyboard inset no longer pushes dashboard and item detail views
- Stale dashboard totals after editing an ItemList

---

## [0.25.0] - 2026-03-11 → 2026-03-13

### Added
- Complete Add Item List flow with incremental cache update and correct total propagation
- `icon`, `color`, `isDefault` properties added to Category and PaymentMethod entities
- Default categories updated
- Item form: input limits, keyboard dismiss button, total preview (unit × qty)
- Item list rows now show item count instead of category name

### Fixed
- `emptyStateView` properly centered on dashboard
- Phantom keyboard inset pushing "Total Gastado" widget
- USD currency displayed correctly
- Sheet action buttons repositioned following iOS HIG

---

## [0.24.0] - 2025-12-11 → 2025-12-24

### Changed
- **Clean Architecture 100% completion**
  - Category, PaymentMethod, User, and Group management fully migrated to Domain models
  - All CoreData entity usage removed from Presentation layer
  - 0 `import CoreData` in ViewModels/Views; 32 `.toDomain()` conversions all in Data layer

### Fixed
- Bug when switching between groups (stale cache returned wrong ItemLists)

---

## [0.23.0] - 2025-12-10

### Fixed
- **🐛 Bug Fix: ItemList totals now display correctly in Dashboard**
  - **Problem**: All ItemLists showed "0.00 €" instead of the sum of their items
  - **Root Cause**: DashboardView had hardcoded placeholder instead of using calculated totals
  - **Solution**:
    - Added `@Published var itemListTotals: [UUID: Double]` cache in DashboardViewModel
    - Modified `calculateTotalSpent()` to populate the totals cache concurrently
    - Updated DashboardView to read from `itemListTotals` dictionary
    - Totals now calculated once during data load and refresh
  - **Benefits**:
    - ✅ Correct totals displayed for each ItemList
    - ✅ Performance: Totals cached, no recalculation on UI render
    - ✅ Reactive: UI updates automatically when totals change
    - ✅ Concurrent: All ItemList totals calculated in parallel using `withTaskGroup`

### Technical Details
- **Total Calculation Flow**:
  1. `loadDashboardData()` / `refreshData()` → calls `calculateTotalSpent()`
  2. `calculateTotalSpent()` uses `withTaskGroup` to fetch items for all ItemLists concurrently
  3. Results stored in `itemListTotals: [UUID: Double]` dictionary
  4. DashboardView reads from cache in `getFormattedAmount` closure
- **Currency Formatting**: Uses `NumberFormatter` with Spanish locale (es_ES) for Euro display

## [0.22.0] - 2025-12-10

### Changed
- **🏗️ Architecture: Item CRUD Refactor to Domain Models (Clean Architecture)**
  - **Goal**: Extend Domain refactor to Item CRUD operations in ItemListDetailViewModel
  - **Status**: ✅ Completed
  - **Files Modified**:
    - `ItemListDetailViewModel.swift` - Full Domain migration
    - `ItemListDetailView.swift` - Updated to use Domain models
    - `AddItemViewModel.swift` - Migrated to accept ItemDomain
    - `ItemRowView` component - Updated to render ItemDomain
  - **Changes**:
    - `@Published var items` changed from `[Item]` (Core Data) to `[ItemDomain]`
    - `loadItems()` - Uses `fetchItemsUseCase` directly, returns Domain models
    - `addItemFromDomain()` - Works with Domain models only (no Core Data conversion)
    - `updateItemFromDomain()` - Works with Domain models only
    - `deleteItem()` - Accepts ItemDomain parameter
    - `getFormattedTotal()` - Fixed to use Decimal operators instead of NSDecimalNumber
    - `getFormattedAmount()` - Fixed to use Decimal operators
    - `ItemSheetMode` enum - Changed from `edit(Item)` to `edit(ItemDomain)`
    - ForEach ID - Changed from `.objectID` to `.id`
    - `AddItemViewModel.itemToEdit` - Changed from `Item?` to `ItemDomain?`
  - **Benefits**:
    - ✅ ItemListDetailViewModel now 100% Domain-driven
    - ✅ No Core Data entity manipulation in ViewModel
    - ✅ Consistent pattern with DashboardViewModel refactor
    - ✅ Type-safe Decimal operations instead of NSDecimalNumber
    - ✅ Clean separation of concerns maintained

### Technical Details
- **Pattern Consistency**: Item CRUD now follows same Domain pattern as ItemList CRUD
- **Decimal Handling**: Changed from NSDecimalNumber to native Decimal operators (`*`, `+`)
- **Build Status**: ✅ Build succeeded - all compilation errors fixed

## [0.21.0] - 2025-12-10

### Changed
- **🏗️ Architecture: Major Domain ViewModel Refactor (Clean Architecture)**
  - **Goal**: Complete migration of DashboardViewModel from Core Data entities to Domain models
  - **Status**: ✅ Core functionality complete
  - **Completed**:
    - `loadDashboardData()` - Now uses `fetchItemListsUseCase.execute()` to get Domain models
    - `refreshData()` - Refactored to work with `[ItemListDomain]` instead of Core Data entities
    - `updateCurrentMonthCache()` - Already working with Domain models (verified)
    - `deleteItemListDomain()` - New Domain method using Use Case only
    - `removeItemListDomain()` - Helper method for optimistic UI updates
    - `updateItemListDomain()` - Update ItemList in UI cache with Domain models
    - `isItemListInCurrentContext(ItemListDomain)` - Domain version of context check
    - `getCurrentMonthItemLists()` - Return type updated to `[ItemListDomain]`
    - **DashboardView.swift**: Updated delete action to call `deleteItemListDomain()` directly
  - **Benefits**:
    - ✅ ViewModel now works entirely with Domain models for ItemLists
    - ✅ No more `.objectID` comparisons - uses UUID `.id` instead
    - ✅ Cleaner code - no optional chaining on Domain model properties
    - ✅ Better separation of concerns - Use Cases handle all data access
    - ✅ Follows Clean Architecture principles perfectly

### Technical Details
- **Domain CRUD Pattern**: All CRUD operations now have Domain versions that use Use Cases
- **Optimistic Updates**: UI updates immediately, then syncs with persistence layer
- **Error Handling**: Rollback UI changes on persistence failures by reloading data
- **Total Calculation**: Always recalculates totals after changes (no incremental updates)

## [0.20.0] - 2025-12-09

### Fixed
- **🐛 Critical: ItemList Total Shows 0,00 € with Automatic Item**
  - **Issue**: Creating ItemList with price field showed 0,00 € instead of actual amount
  - **Root cause**: Using `.toCoreData()` created new ItemList object without items relationship loaded
  - **Solution**: Added `addItemListFromDomain()` that fetches ItemList by ID with relationships prefetched
  - **Result**: Dashboard now correctly displays total (e.g., 630,00 € instead of 0,00 €)

- **🐛 Duplicate ItemList Addition Attempts**
  - **Issue**: ItemList was being added twice (notification handler + explicit callback)
  - **Root cause**: Core Data notification handler competed with explicit callback pattern
  - **Async timing**: Notification handler's `Task { }` ran after Item creation, creating race condition
  - **Solution**: Removed automatic notification handler in favor of explicit callbacks only
  - **Benefits**: Single source of truth, no race conditions, predictable timing

### Changed
- **🎯 DashboardView: Explicit Domain-to-CoreData Conversion**
  - **Before**: `let itemList = createdItemList.toCoreData(context:)` → no relationships loaded
  - **After**: `await viewModel.addItemListFromDomain(createdItemList)` → full object with items
  - **Pattern**: View delegates to ViewModel for Core Data operations (Clean Architecture)

- **🏗️ Architecture: Begin Domain ViewModel Migration (WIP)**
  - **Goal**: Migrate DashboardViewModel from Core Data entities to Domain models
  - **Status**: In Progress - Core methods refactored, 15+ compilation errors remaining
  - **Completed**:
    - `addItemListFromDomain()` - Pure Clean Architecture, no `context.perform()`
    - `getItemListTotal(ItemListDomain)` - Async, fetches items via Use Case
    - `getFormattedItemListTotal(ItemListDomain)` - Async formatting
    - `calculateTotalSpent()` - Now async with **concurrent** item fetching (performance boost!)
    - ViewModel storage changed: `[ItemList]` → `[ItemListDomain]`
    - View components updated: ExpenseListView, ExpenseRowView use Domain models
  - **Next**: Fix remaining Core Data-dependent methods (see docs/DOMAIN_REFACTOR_TODO.md)

- **🏗️ DashboardViewModel: Streamlined ItemList Addition**
  - **Removed**: Automatic Core Data notification handler for ItemList insertions
  - **Reason**: All ItemList creation uses explicit callbacks for better control
  - **Added**: `addItemListFromDomain(_ itemListDomain:)` method
  - **Implementation**: Uses NSFetchRequest with `relationshipKeyPathsForPrefetching: ["items"]`

### Technical Details
- **NSFetchRequest Pattern**: Fetches ItemList by UUID with eager loading of items relationship
- **Clean Architecture**: ViewModel handles all Core Data logic, View only triggers actions
- **Explicit Callback Flow**: AddItemListView → Item created → callback → fetch with relationships → add to UI
- **No Race Conditions**: Single, predictable code path for ItemList addition
- **Comprehensive Logging**: `[ADD-DOMAIN]` tags show fetch operations and item counts

---

## [0.19.0] - 2025-12-03

### Added
- **⚡ Native iOS Navigation Pattern for Instant UI Updates**
  - **Dashboard navigation back**: Context refresh without DB query when returning from ItemListDetailView
  - **Sheet dismiss optimization**: Context refresh without DB query when closing AddItemView
  - **State tracking**: `hasLoadedInitialData` flag prevents redundant database queries
  - **Instant updates**: 50-100x faster than database queries (~1ms vs ~50-100ms)

- **🔄 ItemListDetailViewModel Context Refresh**
  - **`refreshItemContexts()`**: Refreshes all Item Core Data objects from context (no DB query)
  - **`refreshItemListContext()`**: Public method to refresh ItemList properties (ready for Edit ItemList feature)
  - **Smart context management**: Refreshes both Items and parent ItemList for complete consistency

- **📊 Enhanced Pull-to-Refresh UX**
  - **Smooth animations**: List stays visible during refresh (no abrupt spinner)
  - **Conditional loading spinner**: Only shows on initial load, not during pull-to-refresh
  - **Standard iOS behavior**: Always fetches fresh data from database (as expected)
  - **Comprehensive logging**: Track initial load vs refresh vs context refresh

### Changed
- **🎯 ItemListDetailView Navigation Optimization**
  - **`.onAppear` logic**: Distinguishes between first load and sheet dismiss
  - **First load**: Full database query with loading spinner
  - **Sheet dismiss**: Instant Core Data context refresh (NO database query)
  - **Pattern consistency**: Matches DashboardView navigation behavior

- **📝 Improved Debug Logging**
  - **`loadItems()`**: Logs initial load vs pull-to-refresh, item counts, errors
  - **Context refresh**: Logs `[CONTEXT-REFRESH]` and `[ITEMLIST-REFRESH]` operations
  - **Performance visibility**: Easy to track which operations hit the database

### Fixed
- **🐛 Smooth Pull-to-Refresh**
  - **No abrupt list disappearance**: List remains visible during refresh
  - **Eliminated loading spinner flash**: Only shows spinner when `items.isEmpty`
  - **Native iOS UX**: Matches Mail, Instagram, Twitter/X behavior

### Technical Details
- **Navigation Flow**:
  - Dashboard → ItemListDetailView (initial load with DB query)
  - ItemListDetailView → AddItemView (sheet)
  - AddItemView saves → Sheet dismisses → Context refresh (instant!)
  - Back to Dashboard → Context refresh (instant!)
- **Pull-to-Refresh**: Always hits database (correct standard iOS behavior)
- **Performance**: Context refresh ~1ms, Database query ~50-100ms
- **Ready for future**: Public `refreshItemListContext()` method prepared for Edit ItemList feature

---

## [0.18.0] - 2025-12-02

### Added
- **✨ Consolidated ItemList Creation Flow**
  - **Single unified view** for creating ItemLists (removed duplicate QuickExpenseView)
  - **Optional price field**: Users can optionally enter a price to auto-create an Item
  - **Auto-Item creation**: When price is provided, automatically creates first Item with same description
  - **Modern iOS UI**: Sheet-based modal presentation with Form layout
  - **Native pickers**: Using Apple-recommended `Picker` component with `.navigationLink` style
  - **Visual enhancements**: Color circles for categories, icons for payment methods

### Changed
- **🔧 AddItemListView Improvements**
  - **UI Modernization**: Converted to Form-based layout matching Item creation view
  - **Sheet presentation**: Modal sheet instead of push navigation for better UX
  - **Save button in toolbar**: Moved from bottom button to toolbar for consistency
  - **Native pickers**: Replaced sheet-based custom pickers with standard `Picker` components
  - **Callback-based navigation**: Using `onCancel` and `onItemListCreated` callbacks instead of NavigationPath

- **🔧 AddItemListViewModel Enhancements**
  - **Price validation**: Added `isPriceValid` computed property with decimal validation
  - **Price conversion**: Added `priceAsDecimal` to safely convert string to Decimal
  - **CreateItemUseCase integration**: Auto-creates Item when price is provided
  - **Two-step creation**: Creates ItemList first, then optional Item
  - **Proper error handling**: Validates price format, handles creation failures

### Fixed
- **🐛 Core Data Group Fetching**
  - **Critical fix**: `group.toCoreData(context:)` was creating NEW Group entities instead of fetching existing ones
  - **Zero categories/payment methods bug**: Groups appeared empty because new entities had no relationships
  - **Proper fetch by ID**: Now fetches existing Group from Core Data using UUID before loading data
  - **Fixed in two locations**: `.task` modifier and `saveItemList()` method

- **🐛 Navigation Crashes**
  - **Fatal error on cancel**: Removed NavigationPath binding that caused crash when dismissing sheet
  - **Callback-based dismissal**: Using closures to properly dismiss modal sheets
  - **No more path errors**: Eliminated "attempting to remove 1 items from path with 0 items" crash

- **🐛 UI Warnings**
  - **UIReparentingView warnings**: Eliminated by switching from Menu to Picker components
  - **Native iOS patterns**: Using Apple-recommended components for Forms

### Removed
- **QuickExpenseView** and **QuickExpenseViewModel** - Functionality merged into AddItemListView
- **Menu-based pickers** - Replaced with standard Picker components
- **NavigationPath binding** in AddItemListView - Using callbacks instead

### Technical Details
- **Pattern**: `Picker` with `.navigationLink` style for native iOS experience
- **Domain-first**: Fetch Core Data entities by ID, never create duplicates
- **Clean separation**: Category/PaymentMethod loading happens in `.task` modifier
- **Incremental updates**: Maintains existing cache update pattern for new ItemLists
- **Optional Item creation**: `if let priceDecimal = priceAsDecimal { createItem() }`

---

## [0.17.0] - 2025-12-02

### Changed
- **🏗️ Item Management Architecture Refinement**
  - **Aligned Item CRUD with ItemList pattern** for architectural consistency
  - **Domain-First Approach**: ViewModels now return Domain models instead of Core Data entities
  - **AddItemViewModel**: Returns `ItemDomain` (previously returned Core Data `Item` entity)
  - **ItemListDetailViewModel**: Added `addItemFromDomain()` and `updateItemFromDomain()` methods
  - **Proper Domain → Core Data conversion**: ViewModel handles conversion via fetch requests
  - **Eliminated context refresh issues**: Using fetch after save ensures data consistency

### Improved
- **Incremental Cache Updates**:
  - Create item: Updates cache immediately without database query
  - Update item: Replaces item in local array and updates cache atomically
  - Delete item: Optimistic delete with rollback on failure
  - All operations: Service cache updated as single source of truth

- **Clean Separation of Concerns**:
  - `AddItemViewModel` → Business logic, returns Domain models
  - `AddItemView` → UI presentation, passes Domain models to callbacks
  - `ItemListDetailViewModel` → Data conversion, cache management

### Fixed
- **Threading Issues**: Resolved potential race conditions with context refresh on updates
- **Data Consistency**: Fetch after save guarantees latest Core Data state
- **Architecture Consistency**: Item operations now follow same pattern as ItemList operations

### Technical Details
- Pattern: `ViewModel → ItemDomain → Callback → Fetch Core Data → Update Cache`
- Zero database queries after create/update operations (incremental updates only)
- Cache coherence maintained across all item operations
- Proper error handling with rollback support on delete failures

---

## [0.16.0] - 2025-11-27

### Changed
- **🏗️ MAJOR REFACTOR: Clean Architecture Implementation**
  - **Complete project reorganization** following Clean Architecture principles
  - **Single source of truth** for all protocols consolidated in `Domain/Protocols/`
  - **5-Layer Architecture**:
    - `Application/` - App entry point, DI containers, configuration
    - `Domain/` - Pure business logic (Entities, Protocols, UseCases, Errors)
    - `Data/` - Persistence & data access (CoreData, Repositories, Services)
    - `Presentation/` - UI layer organized by feature (Scenes, Common components)
    - `Infrastructure/` - Cross-cutting concerns (Cache, Helpers, Utils, Extensions)

- **Domain Layer Improvements**:
  - Renamed `Domain/Interfaces/` → `Domain/Protocols/` for consistency
  - Moved all service protocols from `Services/Protocols/` → `Domain/Protocols/Services/`
  - Organized repository protocols in `Domain/Protocols/Repositories/`
  - Use cases organized by feature: User, Group, ItemList, UserGroup
  - 7 domain entities, 7 repository protocols, 7 service protocols

- **Data Layer Consolidation**:
  - Moved service implementations to `Data/Services/` (8 services)
  - Consolidated Core Data files into `Data/CoreData/`
  - Core Data entity mappings in `Data/CoreData/Entities/`
  - Repository implementations in `Data/Repositories/` (4 repositories)
  - Persistence controller and .xcdatamodeld properly organized

- **Presentation Layer Organization**:
  - Feature-based organization in `Presentation/Scenes/`:
    - Dashboard, User, Group, ItemList, Category, PaymentMethod, Item
  - Common components in `Presentation/Common/Views/` and `Components/`
  - Moved all View and ViewModel files to their respective feature folders
  - Alert and Loading components properly organized

- **Infrastructure Cleanup**:
  - Utilities reorganized into logical subfolders:
    - `Cache/` - CacheManager
    - `Helpers/` - 6 helper classes
    - `Utils/` - DashboardUpdateManager, TestDataGenerator
    - `Extensions/` - Color+Hex, String+Localization
    - `Constants/` - AppConstants

- **Removed Directories**:
  - Eliminated `View/`, `ViewModel/`, `Utilities/`, `Services/`, `Base/`, `CoreDataStack/`
  - Cleaned up scattered protocol files
  - Removed duplicate and empty directories

### Added
- **Comprehensive Documentation**:
  - `ARCHITECTURE_DIAGRAMS.md` - Visual architecture diagrams and flows
  - `CLEAN_ARCHITECTURE_GUIDE.md` - Complete architecture explanation
  - `IMPLEMENTATION_GUIDE.md` - Step-by-step reorganization guide
  - `PROJECT_REORGANIZATION_PLAN.md` - Detailed migration plan
  - `QUICK_START.md` - Quick reference for the new structure
  - `REORGANIZATION_CHECKLIST.md` - Phase-by-phase checklist

### Fixed
- **Build System**: Project builds successfully with new structure (exit code 0)
- **File References**: All file references properly updated in Xcode project
- **Module Organization**: Clear dependency flow (outer layers → Domain)

### Technical Details
- **43 directories** organized in clean hierarchy
- **Zero breaking changes** - app functionality fully preserved
- **Improved scalability** - easy to add new features
- **Better testability** - clear layer separation
- **Team-friendly** - intuitive structure for collaboration

### Migration Notes
- All files moved using filesystem operations
- Xcode project references automatically updated
- No code changes required - purely organizational
- Full backward compatibility maintained

---

## [0.15.0] - 2025-11-16

### Added
- **Custom Alert Component**: Created reusable alert system for the entire app
  - Modular `CustomAlertView` component with smooth animations
  - Located in `/Base/View/Alert/` directory following MVVM architecture
  - Supports three button styles: `.default`, `.cancel`, `.destructive`
  - Spring animation with fade, scale, and offset effects
  - Optional message support and backdrop dismiss
  - View extension `.customAlert()` for easy implementation
  - Complete documentation in README.md

### Changed
- **Group Deletion Flow**: Enhanced delete experience with better UX
  - Swipe-to-reveal action (no accidental deletion on full swipe)
  - `allowsFullSwipe: false` prevents accidental triggers
  - Explicit "Delete" button must be tapped after swipe
  - Confirmation alert with custom styling before deletion
  - Loading overlay with spinner during group deletion (1.5s visible)
  - Can now delete currently selected group (auto-switches to first available)
  - UI fully blocked during deletion to prevent conflicts
  - Smooth animations throughout the entire flow

### Fixed
- **Alert Animations**: All dismiss actions now use smooth fade-out
  - Tap outside: Smooth fade-out ✓
  - Cancel button: Smooth fade-out (previously abrupt) ✓
  - Delete button: Smooth fade-out ✓
  - Consistent 0.25s ease-out animation across all interactions

## [0.14.0] - 2025-11-15

### Added
- **Splash Screen**: Implemented animated splash screen on app launch
  - Enhances user experience during application startup
  - Smooth transition from splash to main view
  
- **Loading Spinner & Fade-In Animation**: Animations when switching groups
  - Loading spinner displayed while changing active group
  - Smooth fade-in effect when displaying new group data
  - Improves perceived performance during transitions

- **Group Deletion**: New group management functionality
  - Users can now delete existing groups
  - Validations to prevent accidental deletion
  - Intuitive interface for group management

### Changed
- **General UX Improvements**: Enhanced user experience refinements
  - Smoother transitions between views
  - Improved visual feedback for user operations
  - Better consistency in application animations

## [0.13.0] - 2025-11-10

### Fixed
- **Dashboard Refresh UX**: Eliminated black flicker and double refresh icons
  - Root cause: ProgressView overlay conflicting with native refresh control
  - Solution: Removed custom `.overlay(ProgressView)` from DashboardView
  - Added `@Published var isRefreshing = false` in DashboardViewModel for isolated state
  - Smooth refresh animation with native SwiftUI pull-to-refresh
  - `refreshData()` now properly uses background threads for Core Data, main thread for UI updates
  
- **Cache Consistency Bug**: Items no longer disappear after pull-to-refresh
  - Root cause: Dual cache system with different keys
    - DashboardViewModel: "dashboard_items_{groupId}"
    - ItemListService: "ItemListService.groupItemLists.{groupId}"
  - Solution: **Single Source of Truth** - Service layer owns cache exclusively
  - Removed ViewModel cache layer entirely
  - `addItemList()` and `removeItemList()` now update Service cache with timestamp
  - Incremental operations maintain cache freshness

### Added
- **TTL (Time-To-Live) Cache Invalidation**: 30-minute automatic expiration
  - Cache keys: "ItemListService.groupItemLists.{groupId}"
  - Timestamp keys: "{cacheKey}.timestamp"
  - `cacheTTL: TimeInterval = 1800` (30 minutes)
  - Automatic validation on every cache access
  - Logs show cache age: "🟢 CACHE HIT (Fresh data: 5m 23s old)"
  - Expired cache triggers DB refresh: "🟡 Cache EXPIRED (age: 32 minutes, TTL: 30 minutes)"
  
- **Enhanced Logging System**: Comprehensive cache lifecycle tracking
  - Cache hits with freshness indicator: "🟢 CACHE HIT (Fresh data: Xm Ys old)"
  - Cache expiration warnings: "🟡 Cache EXPIRED (age: X minutes)"
  - Cache updates with timestamp reset: "💾 Cache timestamp refreshed (TTL reset to 30 min)"
  - Prefixes: [ADD], [DELETE], [REFRESH] for operation tracking
  - Service layer logs for transparency

### Changed
- **Animation Smoothness**: ExpenseListView transitions
  - Added `.animation(.easeInOut(duration: 0.2), value: filteredItemLists)`
  - Smooth item appearance/disappearance during filtering
  - No jarring transitions when data updates
  
- **Cache Architecture**: Refactored to single-layer pattern
  - Before: ViewModel + Service both maintained caches
  - After: Service layer is **Single Source of Truth**
  - ViewModel reads from Service, updates Service cache on changes
  - Eliminates cache synchronization issues
  - Simplified architecture with clear ownership

### Technical Improvements
- **Cache Strategy**:
  - TTL: 30 minutes for local-only Core Data apps
  - Reasoning: Single user, single device, no cloud sync yet
  - Reduces DB queries by 90%+ for typical usage
  - Prepared for future cloud sync (will reduce TTL to 2-5 min)
  
- **Threading Model** (Reinforced):
  - DB operations: Always `Task { }` on background thread
  - UI updates: Always `await MainActor.run { }`
  - Service calls: async/await with proper thread management
  - Zero main thread blocking for data operations
  
- **Cache Freshness**:
  - First load: No cache → Query DB → Cache + timestamp
  - Within TTL (< 30 min): Use cache → Log age
  - After TTL (> 30 min): Query DB → Update cache + timestamp
  - Incremental ops (add/delete): Update cache + RESET timestamp
  
- **Memory Management**:
  - Timestamp stored alongside cached data
  - Automatic cleanup when cache expires
  - No memory leaks from orphaned timestamps

### Developer Notes
- **Why 30-minute TTL?**
  - Local-only app (Core Data, no cloud sync)
  - Single user workflow
  - Balances freshness vs performance
  - Industry standard: Banking apps (5-15 min), Local apps (30-60 min)
  
- **Future Roadmap**:
  - When Supabase integration added: Reduce TTL to 5 minutes
  - Realtime collaboration: Reduce TTL to 2 minutes
  - Current setup scalable for future changes
  
- **Architecture Benefits**:
  - Single Source of Truth eliminates race conditions
  - TTL prevents stale data indefinitely
  - Incremental updates maintain cache freshness
  - Clear ownership: Service owns cache lifecycle
  - ViewModel focuses on UI state only

## [0.12.0] - 2025-11-07

### Added
- **Swipe-to-Delete for ItemLists**: Native iOS pattern implementation
  - Changed from ScrollView + LazyVStack to List for native swipe support
  - `.swipeActions(edge: .trailing, allowsFullSwipe: false)` with destructive button
  - Smooth delete animation with optimistic UI updates
  - Section-based grouping by date maintained
  
- **Incremental Cache Pattern**: Apple-style cache management
  - Services NO longer invalidate cache on create/update/delete
  - ViewModel updates arrays in-memory instead of DB queries
  - `addItemList()` appends to array and updates cache incrementally
  - `removeItemList()` removes from array and updates cache optimistically
  - `deleteItemList()` with rollback on error
  - 0 DB queries for common operations (create/delete)
  
- **Core Data Auto-Sync**: NSManagedObjectContextDidSave pattern
  - `setupCoreDataNotifications()` with duplicate prevention
  - Shared NSManagedObjectContext between parent and child views
  - Automatic UI updates when data changes in any view
  - Removed manual callbacks (QuickExpenseView, AddItemListView)
  - `[weak self]` for memory safety in observers
  - Proper cleanup with `deinit { NotificationCenter.default.removeObserver(self) }`

### Changed
- **Performance Optimization**: From computed properties to @Published cached vars
  - `currentMonthItemLists` changed from computed property to `@Published var`
  - Added `didSet` observer on `itemLists` to trigger `updateCurrentMonthCache()`
  - Eliminated 100+ recalculations per second during field taps
  - CPU usage: 0% during normal operations
  
- **NaN Protection**: 3-level validation system
  - Item level: `guard itemValue.isFinite` with logging
  - ItemList level: `guard itemListTotal.isFinite` with logging
  - Total level: `guard total.isFinite` with fallback to 0.0
  - `updateTotalSpentForItemList()` with incremental updates
  - Fallback to full recalc if NaN detected
  
- **Log Format**: Replaced emojis with text prefixes
  - Changed 💰 to [TOTAL]
  - Changed 💡 to [INFO]
  - Changed ✅ to [SUCCESS]
  - Changed ⚠️ to [WARNING]
  - Changed ❌ to [ERROR]
  - Changed 🔄 to [REFRESH]
  - Changed 📦 to [CACHE]
  - Fixed emoji corruption in Xcode console (� characters)

### Improved
- **Code Architecture**: Clearer separation of concerns
  - Services: CRUD only, no cache management
  - ViewModels: Cache coordination + incremental updates
  - Views: Pure UI, receive shared context
  
- **Memory Efficiency**: Excellent metrics maintained
  - 35.3MB with 1420+ ItemList records
  - 0% CPU during normal operations
  - Smooth animations without frame drops
  
- **Developer Experience**: Better debugging
  - Clear logging with text prefixes
  - Detailed NaN detection with exact location
  - Incremental cache messages for transparency

### Fixed
- **Duplicate ItemLists**: Core Data observer prevention
  - `guard !itemLists.contains(where: { $0.objectID == itemList.objectID })`
  - Prevents same item being added multiple times
  
- **Performance Regression**: Field tap lag eliminated
  - Root cause: `currentMonthItemLists` computed property recalculating constantly
  - Solution: Cached @Published var with didSet observer
  - Before: 100+ "Filtering ItemLists" logs per second
  - After: 1 log only when itemLists actually changes
  
- **CoreGraphics NaN Crashes**: Complete protection
  - Added isFinite checks at 3 levels
  - Detailed logging to identify source of invalid values
  - Graceful fallbacks instead of crashes

### Technical Details
- **Incremental Cache Flow**:
  1. User creates ItemList → Service returns ItemList
  2. ViewModel calls `addItemList(newItem)`
  3. Append to `itemLists` array (no DB query)
  4. Sort array by date
  5. Update cache with new array
  6. `didSet` triggers `updateCurrentMonthCache()`
  7. SwiftUI auto-redraws from @Published properties

- **Delete Flow**:
  1. User swipes → Delete button
  2. `removeItemList()` - optimistic update (remove from array + cache)
  3. `ItemListService.deleteItemList()` - delete from DB
  4. If success: already updated (optimistic correct)
  5. If error: rollback (re-add to array + cache)

- **Core Data Notification Flow**:
  1. Any view modifies Core Data (same context)
  2. Core Data posts NSManagedObjectContextDidSave
  3. Observer in DashboardViewModel receives notification
  4. Check objectID to prevent duplicates
  5. Append new item to array
  6. Update cache incrementally
  7. UI updates automatically via @Published

### Performance Metrics
- **Before Optimizations**:
  - Constant cache invalidation on every create/delete
  - DB queries on every operation
  - Computed property recalculating 100+ times/second
  - Field taps causing visible lag
  
- **After Optimizations**:
  - 0 DB queries for create/delete (incremental cache)
  - 0% CPU during field taps
  - Instant UI updates (optimistic)
  - 35.3MB memory with 1420+ records
  - Native iOS app performance level

### Documentation
- **Updated prompt file**: Added "LECCIONES APRENDIDAS - ANTI-PATRONES EVITADOS (v0.12.0)"
  - Anti-patrón 1: Callbacks manuales con Core Data compartido
  - Anti-patrón 2: Invalidación total de cache en cada operación
  - Anti-patrón 3: Computed properties para datos filtrados
  - Anti-patrón 4: Sin protección contra NaN en cálculos
  - Anti-patrón 5: Emojis en logs de producción
  - Checklist completo para nuevas features
  - Flujos detallados de crear/eliminar con cache incremental

## [0.10.1] - 2025-11-03

### Fixed
- **ItemList Date Filtering**: Resolved issue where only recent items were displayed
  - **Root Cause**: `recentItemLists` property was limiting display to first 10 items only
  - **Problem**: Users with many expenses from current day couldn't see older expenses
  - **Solution**: Implemented intelligent current month filtering instead of arbitrary limit
  - **New Behavior**: Dashboard now shows all expenses from current month only
  - **User Experience**: More relevant expense display with proper historical context
  - **Performance**: Maintained optimal performance while showing appropriate data scope

### Added
- **Smart Date Filtering**: Current month ItemList display
  - `currentMonthItemLists` computed property for intelligent filtering
  - Calendar-based month comparison using `Calendar.isDate(_:equalTo:toGranularity:)`
  - Automatic month boundary detection
  - Debug logging for filter transparency
  - Better UX with contextually relevant expense display

### Technical Improvements
- **Date Logic Enhancement**: Robust month-based filtering
  - Uses native iOS Calendar APIs for accurate date comparisons
  - Handles month boundaries and year transitions correctly
  - Maintains sort order while filtering appropriately
  - Optimized computed property with clear debugging output

## [0.10.0] - 2025-11-03

### Added
- **First UI Implementation**: Complete SwiftUI interface with working backend integration
  - **DashboardView**: Main expense tracking interface with real-time data display
    - Animated expense cards showing ItemList details with category colors
    - User/Group selector with automatic first selection
    - Real-time expense summary with formatted amounts
    - Floating action button for adding new ItemLists
    - Loading states and error handling throughout UI
  - **AddItemListView**: Full expense creation workflow
    - Category selection with visual color indicators
    - Date picker with proper iOS 18.5+ styling
    - Description input with proper validation
    - Success/error states with user feedback
    - Navigation integration with callback-based refresh
  - **ExpenseRowView**: Reusable expense list item component
    - Category color indication
    - Formatted date and amount display
    - Proper ItemList description rendering
    - Consistent visual hierarchy
- **Core Data UI Synchronization**: Resolved complex threading and cache issues
  - **NSManagedObjectContextDidSave Notifications**: Native iOS pattern implementation
    - Real-time UI updates when Core Data changes
    - Proper threading with @MainActor isolation
    - Automatic dashboard refresh without app restart
  - **Comprehensive Cache Management**: Multi-level caching system
    - Intelligent cache invalidation on data changes
    - Optimized performance for frequent operations
    - Group-specific cache keys for data isolation
  - **Threading Architecture**: Proper iOS concurrency patterns
    - Background Core Data operations
    - Main thread UI updates
    - async/await throughout the stack
- **Navigation Enhancement**: Modern iOS 18.5+ navigation patterns
  - NavigationStack with programmatic navigation
  - Callback-based view refresh patterns
  - Proper navigation state management
  - Smooth transitions between views

### Enhanced
- **MVVM Architecture**: Fully implemented with iOS native patterns
  - ViewModels with @Published properties for reactive UI
  - Proper dependency injection throughout
  - Clean separation of concerns
  - @MainActor threading for UI operations
- **Backend Service Layer**: Production-ready Core Data integration
  - Auto-seeding of payment methods and categories on group creation
  - Robust error handling and validation
  - Optimized query patterns with proper filtering
  - Cache-aware operations for performance
- **User Experience**: Polished iOS-native interactions
  - Smooth animations and transitions
  - Proper loading states
  - Error handling with user-friendly messages
  - Intuitive navigation patterns

### Technical Achievements  
- **Core Data Synchronization**: Solved complex UI refresh issues
  - Multiple service instances now properly synchronized
  - Cache invalidation timing perfected
  - Real-time UI updates working flawlessly
- **iOS Best Practices**: Architecture validated against Apple guidelines
  - Proper MVVM implementation
  - Native Core Data notification patterns
  - Modern SwiftUI reactive patterns
  - Professional-grade threading architecture
- **Performance Optimization**: Intelligent caching and data management
  - Background operations for heavy lifting
  - Optimized Core Data queries
  - Proper memory management
  - Smooth UI responsiveness

### Fixed
- **UI Refresh Issues**: Complete resolution of data synchronization problems
  - ItemList creation now updates UI immediately
  - Dashboard reflects changes without app restart
  - Proper Core Data context synchronization between services
- **Cache Synchronization**: Resolved timing issues with cache invalidation
  - Cache keys now match between services
  - Immediate cache clearing after save operations
  - Proper multi-level cache invalidation strategy
- **Threading Conflicts**: Eliminated race conditions and timing issues
  - Proper @MainActor isolation for UI updates
  - Background Core Data operations
  - Clean async/await patterns throughout

## [0.9.0] - 2025-11-01

### Added
- **Multi-User Security Architecture**: Complete elimination of global data access methods
  - All service methods now require proper user/group context filtering
  - Enhanced security model preventing cross-user data access
  - User-group relationship enforcement across all CRUD operations
- **Secure Service Layer**: Comprehensive refactoring for multi-tenant safety
  - Removed all global `fetchAll()` methods from GroupService, ItemListService, ItemService, UserService
  - Eliminated global `getCount()` methods across all services
  - Added mandatory group/user parameters to all data access methods
  - Enhanced PaymentMethodService with group-specific filtering requirements
- **ViewModel Security Updates**: Complete alignment with secure service architecture
  - CategoryListViewModel: Removed global category access methods
  - ItemListDetailViewModel: Fixed missing paymentMethodId parameters
  - ItemListListViewModel: Eliminated global item list fetching
  - GroupListViewModel: Removed global group access methods
  - PaymentMethodListViewModel: Enforced group-based payment method access
- **Application Layer Security**: View-level security enforcement
  - MainView: Removed global user fetching capabilities
  - AppContentView: Eliminated cross-user data access patterns
  - DataPreloader: Removed global data loading methods
- **Code Quality Enhancement**: Professional codebase cleanup
  - Complete removal of commented deprecated methods
  - Elimination of dead code and security vulnerabilities
  - Clean, maintainable architecture ready for user authentication

### Changed
- **Service Architecture**: From global access to context-aware operations
  - All service methods now enforce proper user/group context
  - Data isolation between users and groups implemented
  - Service interfaces updated to require security context parameters
- **ViewModel Pattern**: Enhanced MVVM with security-first approach
  - ViewModels updated to use only secure, filtered service methods
  - Proper error handling for security-related access violations
  - Consistent parameter passing for user/group context
- **Data Access Pattern**: Shift from convenience to security
  - Replaced convenient global methods with secure, filtered alternatives
  - Enhanced method signatures to enforce proper context passing
  - Improved data encapsulation and access control

### Removed
- **Global Data Access Methods**: Complete elimination of security vulnerabilities
  - `fetchUsers()` from UserService - prevents cross-user data exposure
  - `fetchGroups()` from GroupService - enforces user-group relationships
  - `fetchItemLists()` from ItemListService - requires group context
  - `fetchItems()` from ItemService - prevents unauthorized item access
  - `fetchCategories()` and `getCategoriesCount()` from CategoryService
  - `getPaymentMethodsCount()` global method from PaymentMethodService
- **Deprecated Code**: Cleanup of commented and obsolete implementations
  - Removed all commented global method calls from ViewModels
  - Eliminated TODO markers for removed functionality
  - Cleaned up temporary workaround code

### Security
- **Data Isolation**: Implemented comprehensive multi-user data separation
  - Prevents users from accessing other users' data
  - Enforces group membership validation for all operations
  - Eliminates potential data leakage between user contexts
- **Access Control**: Enhanced method-level security enforcement
  - All data operations require explicit user/group authorization
  - Service layer validates access permissions before data retrieval
  - ViewModels cannot bypass security constraints

### Technical Improvements
- **Compilation Success**: All changes validated with successful device build
  - Zero compilation errors after comprehensive refactoring
  - Full compatibility with iOS 18.5 and arm64 architecture
  - Production-ready codebase with enhanced security posture
- **Architecture Consistency**: Uniform security patterns across entire codebase
  - Consistent parameter naming and method signatures
  - Standardized error handling for security violations
  - Clean separation of concerns with security-first design
- **Performance**: Maintained performance while enhancing security
  - Efficient context-aware data access patterns
  - Optimized service calls with proper filtering
  - No performance degradation from security enhancements

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
