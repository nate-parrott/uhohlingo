import SwiftUI

struct FunButtonOptions {
    var multiline: Bool = false
    var color = Color.blue
    var radius: CGFloat = 10
}

struct FunButtonStyle: ButtonStyle {
    var options = FunButtonOptions()

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(FunButtonModifier(pressed: configuration.isPressed, options: options))
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            }
    }
}

struct FunButtonOnTouchdown<C: View>: View {
    var action: () -> Void
    var options: FunButtonOptions
    @ViewBuilder var label: () -> C

    @State private var pressed = false
    var body: some View {
        label()
            .modifier(FunButtonModifier(pressed: pressed, options: options))
            .onTouchDownGesture { down in
                if down {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }

                pressed = down
                if !down {
                    action()
                }
            }
    }
}

private struct FunButtonModifier: ViewModifier {
    var pressed: Bool
    var options = FunButtonOptions()
    @Environment(\.isEnabled) private var isEnabled


    func body(content: Content) -> some View {
        let rect = RoundedRectangle(cornerRadius: options.radius, style: .continuous)
        let maxRaise: CGFloat = 6
        let raiseAmt: CGFloat = pressed ? 2 : maxRaise

        content
            .foregroundColor(.white)
            .opacity(isEnabled ? 1 : 0.3)
            .font(.funBody)
            .lineLimit(options.multiline ? nil : 1)
            .multilineTextAlignment(options.multiline ? .leading : .center)
            .frame(maxWidth: .infinity, alignment: options.multiline ? .leading : .center)
            .padding()
            .frame(minHeight: 50)
            .background(
                rect
                    .fill(options.color)
            )
            .background(
                rect.fill(options.color).brightness(-0.15)
                    .offset(y: raiseAmt)
            )
            .offset(y: maxRaise - raiseAmt)
            .shadow(color: Color.black.opacity(0.05), radius: 0, x: 0, y: raiseAmt)

    }
}
