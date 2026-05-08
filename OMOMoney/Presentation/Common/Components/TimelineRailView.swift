import SwiftUI

enum TimelinePosition {
    case single
    case first
    case middle
    case last

    var showsTopLine: Bool {
        switch self {
        case .single, .first:
            return false
        case .middle, .last:
            return true
        }
    }

    var showsBottomLine: Bool {
        switch self {
        case .single, .last:
            return false
        case .first, .middle:
            return true
        }
    }
}

struct TimelineRailView: View {
    let position: TimelinePosition
    let color: Color
    var isActive: Bool = true
    var iconName: String? = nil
    var iconColor: Color? = nil
    var lineSegmentHeight: CGFloat = 22

    var body: some View {
        VStack(spacing: 0) {
            lineSegment(visible: position.showsTopLine)
            node
            lineSegment(visible: position.showsBottomLine)
        }
        .frame(width: 28)
    }

    private var node: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isActive ? 0.14 : 0.08))
                .frame(width: 24, height: 24)

            if let iconName {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(iconColor ?? color)
                    .frame(width: 26, height: 26)
            } else {
                Circle()
                    .fill(color.opacity(isActive ? 0.95 : 0.35))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 28)
    }

    private func lineSegment(visible: Bool) -> some View {
        Rectangle()
            .fill(color.opacity(visible ? 0.48 : 0))
            .frame(width: 1.5)
            .frame(height: lineSegmentHeight)
    }
}
