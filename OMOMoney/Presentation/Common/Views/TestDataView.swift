//
//  TestDataView.swift
//  OMOMoney
//
//  Created by Assistant on 5 Nov 2025.
//

import SwiftUI
import SwiftData

struct TestDataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isGenerating = false
    @State private var isCleaning = false
    @State private var statusMessage = ""
    @State private var itemListCount = 500
    @State private var itemsPerList = 3
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Test Data Configuration")) {
                    HStack {
                        Text("ItemLists to generate:")
                        Spacer()
                        TextField("Count", value: $itemListCount, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Items per ItemList:")
                        Spacer()
                        TextField("Count", value: $itemsPerList, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    Text("Total items: \(itemListCount * itemsPerList)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Actions")) {
                    Button(action: generateTestData) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text("Generate Test Data")
                        }
                    }
                    .disabled(isGenerating || isCleaning)
                    
                    Button(action: cleanTestData) {
                        HStack {
                            if isCleaning {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash.circle.fill")
                            }
                            Text("Clean All Test Data")
                        }
                    }
                    .disabled(isGenerating || isCleaning)
                    .foregroundColor(.red)
                }
                
                if !statusMessage.isEmpty {
                    Section(header: Text("Status")) {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Test Data Generator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func generateTestData() {
        isGenerating = true
        statusMessage = "Generating test data..."
        
        Task {
            do {
                let generator = TestDataGenerator(context: modelContext)
                try await generator.generateMassiveTestData(
                    itemListCount: itemListCount,
                    itemsPerList: itemsPerList
                )
                
                await MainActor.run {
                    statusMessage = "✅ Successfully generated \(itemListCount) ItemLists with \(itemListCount * itemsPerList) items!"
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "❌ Error: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
    
    private func cleanTestData() {
        isCleaning = true
        statusMessage = "Cleaning test data..."
        
        Task {
            do {
                let generator = TestDataGenerator(context: modelContext)
                try await generator.cleanAllTestData()
                
                await MainActor.run {
                    statusMessage = "✅ All test data cleaned successfully!"
                    isCleaning = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "❌ Error: \(error.localizedDescription)"
                    isCleaning = false
                }
            }
        }
    }
}

#Preview {
    TestDataView()
        .modelContainer(ModelContainer.preview)
}