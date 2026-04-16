import SwiftUI

struct CategoryManagementView: View {
    let group: GroupDomain

    @State private var viewModel = CategoryListViewModel()
    @State private var sheetMode: SheetMode?

    enum SheetMode: Identifiable {
        case add
        case edit(CategoryDomain)
        var id: String {
            switch self { case .add: return "add"; case .edit(let c): return c.id.uuidString }
        }
    }

    var body: some View {
        List {
            ForEach(viewModel.categories) { category in
                categoryRow(category)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !category.isDefault {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteCategory(category) }
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Categorías")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { sheetMode = .add } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $sheetMode) { mode in
            NavigationStack {
                switch mode {
                case .add:
                    CategoryFormView(group: group, categoryToEdit: nil) { _ in
                        Task { await viewModel.loadCategories(forGroupId: group.id) }
                    }
                case .edit(let category):
                    CategoryFormView(group: group, categoryToEdit: category) { _ in
                        Task { await viewModel.loadCategories(forGroupId: group.id) }
                    }
                }
            }
        }
        .task { await viewModel.loadCategories(forGroupId: group.id) }
    }

    private func categoryRow(_ category: CategoryDomain) -> some View {
        Button { if !category.isDefault { sheetMode = .edit(category) } } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill((Color(hex: category.color) ?? .accentColor).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: category.color) ?? .accentColor)
                }
                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if category.isDefault {
                    Text("Predeterminada")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

