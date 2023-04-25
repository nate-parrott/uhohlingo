import SwiftUI

struct TypingView: View {
    var body: some View {
        ZStack {
            Text(".......")
                .asStandardMessageText
                .opacity(0)
            AnimatedEllipsis()
        }
        .accessibilityRepresentation {
            Text("Typing...")
        }
    }
}

struct AnimatedEllipsis: View {
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.black)
                    .frame(both: 10)
                    .opacity(appeared ? 1 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: appeared)
            }
        }
        .onAppear {
            appeared = true
        }
    }
}
