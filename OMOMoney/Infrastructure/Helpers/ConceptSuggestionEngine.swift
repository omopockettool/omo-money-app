import Foundation

struct ConceptSuggestion {
    let description: String
    let category: SDCategory
}

struct ConceptSuggestionEngine {

    static func getSuggestions(
        query: String,
        amount: Double?,
        forCategory: SDCategory?,
        allCategories: [SDCategory]
    ) -> [ConceptSuggestion] {
        let candidates = buildCandidates(forCategory: forCategory, allCategories: allCategories, amount: amount)
        guard !candidates.isEmpty else { return [] }

        let q = query.trimmingCharacters(in: .whitespaces).lowercased()

        if q.isEmpty {
            return Array(
                candidates
                    .sorted { lhs, rhs in
                        if lhs.sameCategory != rhs.sameCategory { return lhs.sameCategory }
                        if lhs.amountMatch != rhs.amountMatch { return lhs.amountMatch }
                        if lhs.date != rhs.date { return lhs.date > rhs.date }
                        return lhs.count > rhs.count
                    }
                    .prefix(3)
                    .map { ConceptSuggestion(description: $0.name, category: $0.category) }
            )
        }

        let prefixMatches = candidates
            .filter { $0.name.lowercased().hasPrefix(q) }
            .sorted { lhs, rhs in
                if lhs.sameCategory != rhs.sameCategory { return lhs.sameCategory }
                if lhs.amountMatch != rhs.amountMatch { return lhs.amountMatch }
                if lhs.date != rhs.date { return lhs.date > rhs.date }
                return lhs.count > rhs.count
            }

        let containsMatches = candidates
            .filter { !$0.name.lowercased().hasPrefix(q) && $0.name.lowercased().contains(q) }
            .sorted { lhs, rhs in
                if lhs.sameCategory != rhs.sameCategory { return lhs.sameCategory }
                if lhs.amountMatch != rhs.amountMatch { return lhs.amountMatch }
                if lhs.date != rhs.date { return lhs.date > rhs.date }
                return lhs.count > rhs.count
            }

        return Array((prefixMatches + containsMatches).prefix(3).map {
            ConceptSuggestion(description: $0.name, category: $0.category)
        })
    }

    static func lastUsed(forCategory: SDCategory?) -> String? {
        forCategory?.itemLists
            .filter { !$0.itemListDescription.trimmingCharacters(in: .whitespaces).isEmpty }
            .max(by: { $0.date < $1.date })?
            .itemListDescription
    }

    // MARK: - Private

    private struct Candidate {
        let name: String
        var category: SDCategory
        var sameCategory: Bool
        var date: Date
        var count: Int
        var amountMatch: Bool
    }

    private static func buildCandidates(
        forCategory: SDCategory?,
        allCategories: [SDCategory],
        amount: Double?
    ) -> [Candidate] {
        var seen: [String: Candidate] = [:]

        for cat in allCategories {
            let isSelected = cat.id == forCategory?.id
            for list in cat.itemLists {
                let raw = list.itemListDescription.trimmingCharacters(in: .whitespaces)
                guard !raw.isEmpty else { continue }
                let key = raw.lowercased()
                let listTotal = list.items.reduce(0.0) { $0 + $1.totalAmount }
                let matches = amountMatches(listTotal, target: amount)

                if var existing = seen[key] {
                    if isSelected && !existing.sameCategory {
                        // Promote to same-category, preserving accumulated count
                        seen[key] = Candidate(
                            name: raw,
                            category: cat,
                            sameCategory: true,
                            date: list.date,
                            count: existing.count + 1,
                            amountMatch: matches || existing.amountMatch
                        )
                    } else {
                        existing.count += 1
                        if list.date > existing.date { existing.date = list.date }
                        if matches { existing.amountMatch = true }
                        seen[key] = existing
                    }
                } else {
                    seen[key] = Candidate(
                        name: raw,
                        category: cat,
                        sameCategory: isSelected,
                        date: list.date,
                        count: 1,
                        amountMatch: matches
                    )
                }
            }
        }

        return Array(seen.values)
    }

    private static func amountMatches(_ value: Double, target: Double?) -> Bool {
        guard let target, target > 0, value > 0 else { return false }
        return abs(value - target) / target <= 0.05
    }
}
