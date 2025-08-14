import SwiftUI
import CoreData

struct EntryRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: EntryRowViewModel
    private let entry: Entry
    
    init(entry: Entry, context: NSManagedObjectContext) {
        self.entry = entry
        let itemService = ItemService(context: context)
        self._viewModel = StateObject(wrappedValue: EntryRowViewModel(entry: entry, itemService: itemService))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.entryDescription ?? "Sin descripción")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.formatDate(entry.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if viewModel.isCalculatingTotal {
                        StyledLoadingView(message: "", style: .compact)
                    } else {
                        Text(viewModel.formatCurrency(viewModel.entryTotal, currency: "USD"))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let category = entry.category {
                HStack {
                    Circle()
                        .fill(Color(hex: category.color ?? "#007AFF"))
                        .frame(width: 12, height: 12)
                    
                    Text(category.name ?? "Sin categoría")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .task {
            await viewModel.calculateEntryTotal()
        }
    }
}

#Preview {
    EntryRowView(entry: Entry(), context: PersistenceController.preview.container.viewContext)
}
