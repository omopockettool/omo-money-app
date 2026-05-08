import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategoryId: UUID?
    let groupId: UUID

    @Query private var categories: [SDCategory]

    init(selectedCategoryId: Binding<UUID?>, groupId: UUID) {
        self._selectedCategoryId = selectedCategoryId
        self.groupId = groupId
        let id = groupId
        self._categories = Query(
            filter: #Predicate<SDCategory> { $0.group?.id == id },
            sort: \SDCategory.name
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if categories.isEmpty {
                    VStack(spacing: 16) {
                        Text(LocalizationKey.Category.emptyMessage.localized)
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(LocalizationKey.Category.emptyHint.localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(categories, id: \.id) { category in
                            Button(action: {
                                selectedCategoryId = category.id
                                dismiss()
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: category.color) ?? Color.gray)
                                        .frame(width: 20, height: 20)

                                    Text(category.name)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if selectedCategoryId == category.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(LocalizationKey.Category.selectCategory.localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKey.General.cancel.localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CategoryPickerView(
        selectedCategoryId: .constant(nil),
        groupId: UUID()
    )
    .modelContainer(ModelContainer.preview)
}
