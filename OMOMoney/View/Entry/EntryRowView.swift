import CoreData
import SwiftUI

struct EntryRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: EntryRowViewModel
    private let entry: Entry
    
    private var categoryColor: Color {
        guard let category = entry.category,
              let colorString = category.color else {
            return .blue
        }
        
        // Map common hex colors to system colors
        switch colorString.lowercased() {
        case "#ff0000", "#ff3b30": return .red
        case "#00ff00", "#34c759": return .green
        case "#0000ff", "#007aff": return .blue
        case "#ffff00", "#ffcc00": return .yellow
        case "#ff00ff", "#ff2d92": return .pink
        case "#00ffff", "#5ac8fa": return .cyan
        case "#ff8000", "#ff9500": return .orange
        case "#8000ff", "#af52de": return .purple
        case "#808080", "#8e8e93": return .gray
        case "#000000": return .black
        default: return .blue
        }
    }
    
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
                        .fill(categoryColor)
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
