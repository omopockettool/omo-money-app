import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SDUser.self,
            SDGroup.self,
            SDUserGroup.self,
            SDCategory.self,
            SDPaymentMethod.self,
            SDItemList.self,
            SDItem.self
        ]
    }
}

typealias OMOMoneySchema = SchemaV1
