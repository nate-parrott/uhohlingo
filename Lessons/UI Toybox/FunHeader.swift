import SwiftUI

struct FunHeader<B1: View, B2: View>: View {
    var title: String
    @ViewBuilder var leadingButton: () -> B1
    @ViewBuilder var trailingButton: () -> B2

    var body: some View {
        FunHeaderBase(center: {
//            RandomColorView()
            Text(title)
                .font(.funHeader)
                .padding(.vertical)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }, leadingButton: leadingButton, trailingButton: trailingButton)
    }
}

struct FunHeaderBase<B1: View, B2: View, C: View>: View {
    @ViewBuilder var center: () -> C
    @ViewBuilder var leadingButton: () -> B1
    @ViewBuilder var trailingButton: () -> B2

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                leadingButton()
                trailingButton().opacity(0).accessibilityHidden(true) // for spacing
            }

            Spacer()

            center()

            Spacer()

            ZStack(alignment: .trailing) {
                trailingButton()
                leadingButton().opacity(0).accessibilityHidden(true) // for spacing
            }
        }
        .frame(minHeight: 54)
        .buttonStyle(FunHeaderButtonStyle())
        .background(Color.white.opacity(0.3))
    }
}


struct FunHeaderButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.funHeaderButton)
            .foregroundColor(Color.blue)
            .opacity(isEnabled ? 1 : 0.3)
            .padding()
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "arrow.backward")
                .accessibilityLabel("Back")
        }
    }
}
