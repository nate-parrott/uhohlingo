import SwiftUI

struct ScrollableCenteredView_Vertical<T: View>: View {
    var horizontalAlignment: HorizontalAlignment = .center
    @ViewBuilder var content: () -> T

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                content()
                    .frame(maxWidth: .infinity, alignment: .init(horizontal: horizontalAlignment, vertical: .center))
                    .frame(minHeight: geometry.size.width)
            }
        }
    }
}
