import CoreGraphics

enum ExpenseListLayoutMetrics {
    static func topContentOffset(
        hideSectionHeaders: Bool,
        availableHeight: CGFloat
    ) -> CGFloat {
        guard !hideSectionHeaders else { return 0 }

        // Keep month-mode compensation responsive without forcing
        // section headers too close to the rounded container edge.
        let responsiveOffset = -(availableHeight * 0.004)
        return min(-2, max(-4, responsiveOffset))
    }

    static func sectionHeaderTopPadding(
        hideSectionHeaders: Bool,
        availableHeight: CGFloat
    ) -> CGFloat {
        guard !hideSectionHeaders else { return 0 }
        return max(4, min(8, availableHeight * 0.006))
    }
}
