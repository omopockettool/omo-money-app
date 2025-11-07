import SwiftUI
import CoreData

struct QuickExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    
    let user: User
    let group: Group
    let context: NSManagedObjectContext
    
    @StateObject private var viewModel: QuickExpenseViewModel
    
    // MARK: - Initialization
    
    init(user: User, group: Group, context: NSManagedObjectContext) {
        self.user = user
        self.group = group
        self.context = context
        
        // Initialize services with provided context
        let itemListService = ItemListService(context: context)
        let categoryService = CategoryService(context: context)
        let itemService = ItemService(context: context)
        let paymentMethodService = PaymentMethodService(context: context)
        
        print("🔄 QuickExpenseView: Initializing with same context as parent")
        
        self._viewModel = StateObject(wrappedValue: QuickExpenseViewModel(
            itemListService: itemListService,
            categoryService: categoryService,
            itemService: itemService,
            paymentMethodService: paymentMethodService
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    formFieldsSection
                }
            }
            .navigationTitle("Nuevo Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                Task {
                    await viewModel.loadInitialData(for: group)
                }
            }
            .onChange(of: viewModel.expenseCreatedSuccessfully) { _, success in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Nuevo Gasto Rápido")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("Crea un gasto rápido. Si agregas precio, se creará un item automáticamente.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var formFieldsSection: some View {
        VStack(spacing: 16) {
            priceField
            descriptionField
            categoryDropdown
            paymentMethodDropdown
            datePicker
            createButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var priceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Precio")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Button(action: {
                    // Show info about price field
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Spacer()
                
                Text("€")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            TextField("0.00", text: $viewModel.price)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(viewModel.isPriceValid ? Color.clear : Color.red, lineWidth: 1)
                )
            
            if !viewModel.isPriceValid {
                Text("Precio inválido")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Descripción")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            TextField("Ej: Gimnasio, Supermercado...", text: $viewModel.description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var categoryDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("Categoría")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            categoryMenu
        }
    }
    
    private var categoryMenu: some View {
        Menu {
            ForEach(viewModel.categories, id: \.id) { category in
                Button(action: {
                    viewModel.selectedCategory = category
                }) {
                    HStack {
                        Circle()
                            .fill(Color(hex: category.color ?? "#8E8E93") ?? Color.gray)
                            .frame(width: 12, height: 12)
                        
                        Text(category.name ?? "Sin nombre")
                    }
                }
            }
            
            if viewModel.selectedCategory != nil {
                Divider()
                Button("Limpiar selección") {
                    viewModel.selectedCategory = nil
                }
            }
        } label: {
            categoryMenuLabel
        }
    }
    
    private var categoryMenuLabel: some View {
        HStack {
            if let category = viewModel.selectedCategory {
                Circle()
                    .fill(Color(hex: category.color ?? "#8E8E93") ?? Color.gray)
                    .frame(width: 12, height: 12)
                
                Text(category.name ?? "Sin nombre")
                    .foregroundColor(.primary)
            } else {
                Text("Seleccionar Categoría")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private var paymentMethodDropdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Método de Pago")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            paymentMethodMenu
        }
    }
    
    private var paymentMethodMenu: some View {
        Menu {
            ForEach(viewModel.paymentMethods, id: \.id) { paymentMethod in
                Button(action: {
                    viewModel.selectedPaymentMethod = paymentMethod
                }) {
                    HStack {
                        Image(systemName: paymentMethodIcon(for: paymentMethod.type ?? ""))
                            .foregroundColor(paymentMethodColor(for: paymentMethod.type ?? ""))
                        
                        Text(paymentMethod.name ?? "Sin nombre")
                    }
                }
            }
            
            if viewModel.selectedPaymentMethod != nil {
                Divider()
                Button("Limpiar selección") {
                    viewModel.selectedPaymentMethod = nil
                }
            }
        } label: {
            paymentMethodMenuLabel
        }
    }
    
    private var paymentMethodMenuLabel: some View {
        HStack {
            if let paymentMethod = viewModel.selectedPaymentMethod {
                Image(systemName: paymentMethodIcon(for: paymentMethod.type ?? ""))
                    .foregroundColor(paymentMethodColor(for: paymentMethod.type ?? ""))
                    .font(.title3)
                
                Text(paymentMethod.name ?? "Sin nombre")
                    .foregroundColor(.primary)
            } else {
                Text("Seleccionar Método de Pago")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                    .font(.caption)
                
                Text("Fecha")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var createButton: some View {
        Button(action: {
            Task {
                await createQuickExpense()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                
                Text(viewModel.isLoading ? "Creando..." : "Crear Gasto")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSave && viewModel.isPriceValid ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSave || !viewModel.isPriceValid || viewModel.isLoading)
    }
    
    // MARK: - Private Methods
    
    private func createQuickExpense() async {
        print("🔄 QuickExpenseView: Creating quick expense...")
        
        if let createdItemList = await viewModel.createQuickExpense(group: group) {
            print("✅ QuickExpenseView: Quick expense created: '\(createdItemList.itemListDescription ?? "Unknown")'")
            print("[INFO] QuickExpenseView: Core Data notification will trigger DashboardViewModel update")
            // No callback needed - NSManagedObjectContextDidSave notification handles it
        } else {
            print("❌ QuickExpenseView: Failed to create quick expense")
        }
    }
    
    private func paymentMethodIcon(for type: String) -> String {
        switch type.lowercased() {
        case "card_debit", "card_credit", "card":
            return "creditcard.fill"
        case "cash":
            return "banknote.fill"
        case "bank_transfer", "transfer":
            return "arrow.left.arrow.right"
        case "digital":
            return "iphone"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func paymentMethodColor(for type: String) -> Color {
        switch type.lowercased() {
        case "card_debit", "card_credit", "card":
            return .blue
        case "cash":
            return .green
        case "bank_transfer", "transfer":
            return .orange
        case "digital":
            return .purple
        default:
            return .gray
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create test data
    let user = User(context: context)
    user.id = UUID()
    user.name = "Test User"
    user.email = "test@example.com"
    
    let group = Group(context: context)
    group.id = UUID()
    group.name = "Test Group"
    group.currency = "EUR"
    
    return QuickExpenseView(
        user: user,
        group: group,
        context: context
    )
}