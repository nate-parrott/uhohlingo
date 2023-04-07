import SwiftUI

struct FunProgressView: View {
    enum Size: Equatable {
        case small
        case large
    }
    var size: Size = .small

    var body: some View {
        // TODO: Better
        ProgressView()
    }
}

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

struct FunHeader<B1: View, B2: View>: View {
    var title: String
    @ViewBuilder var leadingButton: () -> B1
    @ViewBuilder var trailingButton: () -> B2

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                leadingButton()
                trailingButton().opacity(0).accessibilityHidden(true) // for spacing
            }

            Spacer()

            Text(title)
                .font(.funHeader)
                .padding(.vertical)

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
            .font(.funHeader)
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


extension Font {
    static var funBody: Font {
        .system(.headline, design: .rounded, weight: .medium)
    }
    static var funHeader: Font {
        .system(.title3, design: .rounded, weight: .bold)
    }
}

extension View {
    @ViewBuilder var asFunList: some View {
        self
            .font(.funBody)
            .scrollContentBackground(.hidden)
            .background(Color.yellow)
//            .blendMode(.luminosity)
    }

    @ViewBuilder var asFunListCell: some View {
        self
            .alignmentGuide(.listRowSeparatorLeading) { d in
                        -30
                    }
//            .listRowSeparator(.hidden)
//            .listRowSeparator(.visible, edges: .bottom)
            .listRowSeparatorTint(Color.black.opacity(0.2))
            .listRowBackground(Color.white.opacity(0.7))
            .padding(.vertical, 8)
            .padding(.horizontal, 3)
    }
}

struct FunFloatingButton<C: View>: View {
    var action: () -> Void
    @ViewBuilder var content: () -> C

    var body: some View {
        FunButtonOnTouchdown(action: action, options: .init(radius: 60)) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 60)
    }
}

struct FunScreen<C: View>: View {
    @ViewBuilder var content: () -> C

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(.yellow)
        .font(.funBody)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct Toybox_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            Text("Hello")
                .font(.system(.title, design: .rounded, weight: .semibold))
            FunButtonOnTouchdown(action: {}, options: .init()) {
                Text("Sign Up")
            }
            Button("One two three four five six seven eight nine ten eleven twelve.") {}
                .buttonStyle(FunButtonStyle(options: .init(multiline: true)))
        }
        .padding()
        .frame(maxHeight: .infinity)
        .background(Color.yellow)

        VStack(spacing: 0) {
            FunHeader(title: "Hello World", leadingButton: {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                }
            }, trailingButton: {
                Button(action: {}) {
                    Text("Add")
                }
            })

            List {
                Text("Hi")
                    .asFunListCell

                Text("My Cell")
                    .asFunListCell
            }
            .asFunList
        }
        .background(Color.yellow)

        FunScreen {
            Text("My screen")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 30) {
                FunFloatingButton(action: {}) {
                    Text("Add")
                }
                FunFloatingButton(action: {}) {
                    Image(systemName: "plus")
                }
            }
            .padding(30)
        }
    }
}
