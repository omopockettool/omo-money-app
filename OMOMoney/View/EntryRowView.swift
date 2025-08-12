import SwiftUI
import CoreData

struct EntryRowView: View {
    let entry: Entry
    @StateObject private var viewModel: EntryRowViewModel
    
    init(entry: Entry) {
        self.entry = entry
        self._viewModel = StateObject(wrappedValue: EntryRowViewModel(entry: entry))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Entry Icon
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            // Entry Details
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.entryDescription ?? "Sin descripción")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let date = entry.date {
                    Text(viewModel.formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let category = entry.category {
                    Text(category.name ?? "Sin categoría")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Entry Amount
            VStack(alignment: .trailing, spacing: 4) {
                if viewModel.isCalculatingTotal {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Text(viewModel.formatCurrency(viewModel.entryTotal))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text("\(entry.items?.count ?? 0) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            viewModel.calculateEntryTotal()
        }
    }
    

}
