import SwiftUI

struct DashboardBottomBarView: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    let dismissKeyboardToken: Int

    let currentGroup: SDGroup?
    let availableGroups: [SDGroup]
    let userId: UUID?
    let isChangingGroup: Bool
    let isFilterActive: Bool
    let onGroupChange: (SDGroup) -> Void
    let onGroupCreated: (SDGroup) -> Void
    let onDeleteGroup: (SDGroup) async throws -> Void
    let onOpenFilters: () -> Void

    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchFocusTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack(alignment: .trailing) {
            inactiveContent
                .opacity(isSearchActive ? 0 : 1)
                .offset(y: isSearchActive ? 8 : 0)
                .scaleEffect(isSearchActive ? 0.98 : 1, anchor: .trailing)
                .allowsHitTesting(!isSearchActive)

            searchContent
                .opacity(isSearchActive ? 1 : 0)
                .offset(y: isSearchActive ? 0 : 8)
                .scaleEffect(isSearchActive ? 1 : 0.98, anchor: .trailing)
                .allowsHitTesting(isSearchActive)
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.top, AppConstants.UserInterface.smallPadding)
        .padding(.bottom, AppConstants.UserInterface.smallPadding)
        .background(Color(.systemBackground).ignoresSafeArea(edges: .bottom))
        .animation(AnimationHelper.quickEase, value: isSearchActive)
        .onChange(of: isSearchActive) { _, isActive in
            searchFocusTask?.cancel()

            if isActive {
                searchFocusTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(180))
                    guard !Task.isCancelled, isSearchActive else { return }
                    isSearchFieldFocused = true
                }
            } else {
                isSearchFieldFocused = false
            }
        }
        .onChange(of: dismissKeyboardToken) { _, _ in
            searchFocusTask?.cancel()
            isSearchFieldFocused = false
        }
        .onAppear {
            isSearchFieldFocused = false
        }
        .onDisappear {
            searchFocusTask?.cancel()
            isSearchFieldFocused = false
        }
    }

    private var searchContent: some View {
        HStack(spacing: AppConstants.UserInterface.smallPadding) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)

                TextField(LocalizationKey.General.search.localized, text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)

                Button {
                    closeSearchMode()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
        }
    }

    private var inactiveContent: some View {
        HStack(spacing: AppConstants.UserInterface.smallPadding) {
            if let currentGroup, let userId {
                GroupSelectorChipView(
                    currentGroup: currentGroup,
                    availableGroups: availableGroups,
                    userId: userId,
                    isChangingGroup: isChangingGroup,
                    onGroupChange: onGroupChange,
                    onGroupCreated: onGroupCreated,
                    onDeleteGroup: onDeleteGroup
                )
            }

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                Button(action: onOpenFilters) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isFilterActive ? .accentColor : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(PressHapticButtonStyle())

                Divider()
                    .frame(height: 16)

                Button {
                    isSearchActive = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(PressHapticButtonStyle())
            }
            .background(Color(.systemGray5))
            .clipShape(Capsule())
        }
    }

    private func closeSearchMode() {
        searchFocusTask?.cancel()
        isSearchFieldFocused = false

        withAnimation(AnimationHelper.quickEase) {
            isSearchActive = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            guard !isSearchActive else { return }
            searchText = ""
        }
    }
}
