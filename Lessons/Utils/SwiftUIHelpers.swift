import SwiftUI

extension View {
    func onAppearOrChange<T: Equatable>(of value: T, perform action: @escaping (T) -> Void) -> some View {
        onAppear {
            action(value)
        }
        .onChange(of: value, perform: action)
    }
}

struct EnumeratedIdentifiable<T>: Identifiable {
    let index: Int
    let value: T

    var id: Int { index }
}

extension EnumeratedIdentifiable: Equatable where T: Equatable {}

extension Array {
    func enumeratedIdentifiable() -> [EnumeratedIdentifiable<Element>] {
        enumerated().map { EnumeratedIdentifiable(index: $0, value: $1) }
    }
}

// From https://stackoverflow.com/questions/57860840/any-swiftui-button-equivalent-to-uikits-touch-down-i-e-activate-button-when
extension View {
    func onTouchDownGesture(_ perform: @escaping (Bool /* down */) -> Void) -> some View {
        modifier(TouchDownGestureModifier(perform: perform))
    }
}

private struct TouchDownGestureModifier: ViewModifier {
    @State private var tapped = false
    let perform: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { val in
                    let isTapped = true // todo: handle moving finger outside
                    if tapped != isTapped {
                        tapped = isTapped
                        perform(isTapped)
                    }
                }
                .onEnded { _ in
                    tapped = false
                    perform(false)
                })
    }
}

extension View {
    var asAny: AnyView { AnyView(self) }

    func frame(both: CGFloat, alignment: Alignment = .center) -> some View {
        self.frame(width: both, height: both, alignment: alignment)
    }
}

extension String {
    var asText: Text {
        Text(self)
    }
}
