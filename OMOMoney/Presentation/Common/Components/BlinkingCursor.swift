import SwiftUI

struct BlinkingCursor: View {
    let height: CGFloat
    @State private var visible = true

    var body: some View {
        Rectangle()
            .frame(width: 2.5, height: height)
            .cornerRadius(1.5)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
    }
}
