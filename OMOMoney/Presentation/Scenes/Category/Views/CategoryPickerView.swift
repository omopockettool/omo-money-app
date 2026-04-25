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
                        Text("No hay categorías disponibles")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Las categorías se crean automáticamente cuando se crea un grupo")
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
            .navigationTitle("Seleccionar Categoría")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
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
