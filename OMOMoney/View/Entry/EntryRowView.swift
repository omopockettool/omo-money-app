import SwiftUI
import CoreData

struct EntryRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: EntryRowViewModel
    
    init(entry: Entry, context: NSManagedObjectContext) {
        self._viewModel = StateObject(wrappedValue: EntryRowViewModel(entry: entry, context: context))
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
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(viewModel.formatCurrency(viewModel.entryTotal, "USD"))
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
