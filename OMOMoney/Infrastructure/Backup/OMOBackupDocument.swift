import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let omoBackup = UTType(exportedAs: "com.omo.backup", conformingTo: .json)
}

struct OMOBackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.omoBackup, .json]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw OMOBackupError.invalidFileContents
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
