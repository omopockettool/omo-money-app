import SwiftUI
import CoreData

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedCategoryId: UUID?
    let groupId: UUID

    @StateObject private var viewModel: CategoryPickerViewModel

    /// ✅ CLEAN ARCHITECTURE: Uses convenience initializer with DI Container
    init(selectedCategoryId: Binding<UUID?>, groupId: UUID, context: NSManagedObjectContext) {
        self._selectedCategoryId = selectedCategoryId
        self.groupId = groupId

        // Use convenience initializer that gets Use Cases from DI Container
        self._viewModel = StateObject(wrappedValue: CategoryPickerViewModel())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingView(message: "Cargando categorías...")
                        .padding()
                } else if viewModel.categories.isEmpty {
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
                        ForEach(viewModel.categories, id: \.id) { category in
                            Button(action: {
                                selectedCategoryId = category.id
                                dismiss()
                            }) {
                                HStack {
                                    // Category color indicator
                                    Circle()
                                        .fill(Color(hex: category.color) ?? Color.gray)
                                        .frame(width: 20, height: 20)

                                    // Category name
                                    Text(category.name)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    // Selection indicator
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
        .task {
            await viewModel.loadCategories(forGroupId: groupId)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let groupId = UUID()

    CategoryPickerView(
        selectedCategoryId: .constant(nil),
        groupId: groupId,
        context: context
    )
}
