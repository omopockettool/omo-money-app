import CoreData
import SwiftUI

struct ItemListRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ItemListRowViewModel
    private let itemList: ItemList
    private let groupCurrency: String
    
    private var categoryColor: Color {
        guard let category = itemList.category,
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
    
    init(itemList: ItemList, context: NSManagedObjectContext, groupCurrency: String = "USD") {
        self.itemList = itemList
        self.groupCurrency = groupCurrency
        let itemService = ItemService(context: context)
        self._viewModel = StateObject(wrappedValue: ItemListRowViewModel(itemList: itemList, itemService: itemService))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemList.itemListDescription ?? "Sin descripción")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(viewModel.formatDate(itemList.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if viewModel.isCalculatingTotal {
                        StyledLoadingView(message: "", style: .compact)
                    } else {
                        Text(viewModel.formatCurrency(viewModel.itemListTotal, currency: groupCurrency))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let category = itemList.category {
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
            await viewModel.calculateItemListTotal()
        }
    }
}

#Preview {
    ItemListRowView(
        itemList: ItemList(), 
        context: PersistenceController.preview.container.viewContext,
        groupCurrency: "USD"
    )
}
