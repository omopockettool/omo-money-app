import SwiftUI
import CoreData

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedCategory: Category?
    let group: Group
    
    @StateObject private var viewModel: CategoryPickerViewModel
    
    init(selectedCategory: Binding<Category?>, group: Group, context: NSManagedObjectContext) {
        self._selectedCategory = selectedCategory
        self.group = group
        
        let categoryService = CategoryService(context: context)
        self._viewModel = StateObject(wrappedValue: CategoryPickerViewModel(
            categoryService: categoryService
        ))
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
                                selectedCategory = category
                                dismiss()
                            }) {
                                HStack {
                                    // Category color indicator
                                    Circle()
                                        .fill(Color(hex: category.color ?? "#8E8E93"))
                                        .frame(width: 20, height: 20)
                                    
                                    // Category name
                                    Text(category.name ?? "Sin nombre")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Selection indicator
                                    if selectedCategory?.id == category.id {
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
            await viewModel.loadCategories(for: group)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let group = Group(context: context)
    group.id = UUID()
    group.name = "Test Group"
    
    return CategoryPickerView(
        selectedCategory: .constant(nil),
        group: group,
        context: context
    )
}
