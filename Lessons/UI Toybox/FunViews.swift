import SwiftUI

struct RandomColorView: View {
    @State private var color = Color.gray

    var body: some View {
        Circle()
            .fill(color)
            .frame(both: 20)
            .onAppear {
                let colors: [Color] = [.blue, .purple, .pink, .yellow, .green, .orange, .red, .teal, .brown, .cyan]
                self.color = colors.randomElement()!
            }
    }
}

struct FunProgressView: View {
    enum Size: Equatable {
        case small
        case large
    }
    var size: Size = .small

    var body: some View {
        AnimatedEllipsis()
    }
}

extension Font {
    static var funBody: Font {
        .system(.headline, design: .rounded, weight: .medium)
    }
    static var funHeader: Font {
        .system(.title3, design: .rounded, weight: .bold)
    }
    static var funHeaderButton: Font {
        .system(.title3, design: .rounded, weight: .bold)
    }
}

extension UIFont {
    static var funBody: UIFont {
        let pointSize = UIFont.preferredFont(forTextStyle: .headline).pointSize
        let fontDescriptor = UIFont.systemFont(ofSize: pointSize, weight: .medium)
            .fontDescriptor
            .withDesign(.rounded)!
            .withSymbolicTraits(.traitBold)
        return UIFont(descriptor: fontDescriptor!, size: pointSize)
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

//struct FunFloatingButton<C: View>: View {
//    var action: () -> Void
//    @ViewBuilder var content: () -> C
//
//    var body: some View {
//        FunButtonOnTouchdown(action: action, options: .init(radius: 60)) {
//            content()
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//        .frame(height: 60)
//    }
//}

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
//        .overlay(alignment: .bottomTrailing) {
//            HStack(spacing: 30) {
//                FunFloatingButton(action: {}) {
//                    Text("Add")
//                }
//                FunFloatingButton(action: {}) {
//                    Image(systemName: "plus")
//                }
//            }
//            .padding(30)
//        }
    }
}

struct LoaderFeather: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.yellow.opacity(0), Color.yellow], startPoint: .top, endPoint: .init(x: 0.5, y: 0.7))
                .edgesIgnoringSafeArea(.all)
            FunProgressView()
                .padding()
                .offset(y: 50)
        }
        .frame(height: 150)
        .allowsHitTesting(false)
    }
}
