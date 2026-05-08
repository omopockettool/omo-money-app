import SwiftUI

struct NativeSettingsRowIcon: View {
    let systemName: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(color.gradient)
            .frame(width: 30, height: 30)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

struct NativeSettingsRow<Accessory: View>: View {
    let systemImage: String
    let color: Color
    let title: String
    let accessory: Accessory

    init(
        systemImage: String,
        color: Color,
        title: String,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.color = color
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: 12) {
            NativeSettingsRowIcon(systemName: systemImage, color: color)
            Text(title)
            Spacer(minLength: 8)
            accessory
        }
        .contentShape(Rectangle())
    }
}
