import SwiftUI

struct FunTextEntry: View {
    @Binding var text: String
    var autoFocus = true
    var options: BridgedTextView.Options
    var cornerRadius: CGFloat = 0

    @State private var focusId = 0

    var body: some View {
        let rect = RoundedRectangle(cornerRadius: 10)
        let border: CGFloat = 3

        BridgedTextView(text: $text, options: processedOptions)
            .cornerRadius(10)
            .clipped()
            .background {
                ZStack {
                    rect.fill(Color.white)
                    rect.stroke(lineWidth: border)
                        .opacity(0.5)
                }
                .opacity(0.3)
            }
            .padding(border)
            .onAppear {
                if autoFocus {
                    self.focusId += 1
                }
            }
    }

    private var processedOptions: BridgedTextView.Options {
        var ops = self.options
        ops.xPadding = 12
        ops.yPadding = 20
        ops.focusId = focusId
        return ops
    }
}

// Previews

struct FunTextField_Previews: PreviewProvider {
    static var previews: some View {
        FunScreen {
            FunHeader(title: "Text Field", leadingButton: { BackButton() }, trailingButton: { EmptyView() })
            FunTextEntry(text: .constant("Hello world"), options: .init())
                .padding(Constants.slideMargin)
        }
    }
}
