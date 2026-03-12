import SwiftUI

struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 8) {
                // Wordmark
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("omo")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("ni")
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                }

                // Tagline
                Text("your things. on your own terms.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .tracking(0.3)
            }
            .scaleEffect(appeared ? 1 : 0.88)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
