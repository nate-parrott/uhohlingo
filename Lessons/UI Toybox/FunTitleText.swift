import SwiftUI

struct FunTitleText: View {
    var text: String

    var body: some View {
        ZStack {
//            label
//                .repeater(distance: CGSize(width: 3, height: 5), replicas: 3, brightnessStart: -0.1, brightnessEnd: -0.3)
//                .paddedDrawingGroup(40)
//                .drawingGroup()
//                .opacity(0.3)
            label
        }
    }

    @ViewBuilder private var label: some View {
        SelfSizingText(text: text.uppercased(), fontName: "Lilita One", fontAlignment: .center, fillColor: UIColor(named: "LightBlue")!, strokeColor: UIColor(named: "DarkBlue")!, strokeWidthProportion: 0)
//        text
//            .lineSpacing(12)
//            .kerning(1)
//            .textCase(.uppercase)
//            .font(.custom("Lilita One", size: 40))
//            .italic()
//            .foregroundColor(.blue)
////            .rotation3DEffect(.degrees(10), axis: (x: 1, y: -0.5, z: -1), perspective: 1)
    }
}

struct SelfSizingText: View {
    var text: String
    var fontName: String
    var fontAlignment = TextAlignment.leading
    var verticalAligmment = VerticalAlignment.center
    var fillColor: UIColor = UIColor.blue
    var strokeColor: UIColor = UIColor.red
    var strokeWidthProportion: CGFloat = 0.1

    var body: some View {
        Canvas { context, size in
            context.withCGContext { cg in
                let fontSize = computeFontSize(text: text, fontName: fontName, maximum: 100, bounds: size)
                let font = UIFont(name: fontName, size: fontSize)!
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = fontAlignment.asNsTextAlignment
                let strokeWidth = -round(fontSize * strokeWidthProportion)
                let attributed = NSAttributedString(
                    string: text,
                    attributes: [.font: font, .paragraphStyle: paragraphStyle, .foregroundColor: fillColor, .strokeColor: strokeColor, .strokeWidth: strokeWidth]
                )
                let textSize = attributed
                    .boundingRect(with: CGSize(width: size.width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).size
                let origin = computeOrigin(forItemOfSize: textSize, withinBox: size, horizontalAlignment: fontAlignment, verticalAlignment: verticalAligmment)
                UIGraphicsPushContext(cg)
                fillColor.setFill()
                strokeColor.setStroke()
                cg.setLineWidth(1)
                attributed.draw(in: .init(origin: origin, size: textSize))
                UIGraphicsPopContext()
            }
        }
    }
}

extension TextAlignment {
    var asNsTextAlignment: NSTextAlignment {
        switch self {
        case .leading:
            return .left
        case .center:
            return .center
        case .trailing:
            return .right
        }
    }
}

private func computeOrigin(forItemOfSize size: CGSize, withinBox boxSize: CGSize, horizontalAlignment: TextAlignment, verticalAlignment: VerticalAlignment) -> CGPoint {
    var origin: CGPoint = .zero
    switch horizontalAlignment {
    case .leading:
        origin.x = 0
    case .center:
        origin.x = (boxSize.width - size.width) / 2
    case .trailing:
        origin.x = boxSize.width - size.width
    }
    switch verticalAlignment {
    case .top:
        origin.y = 0
    case .center:
        origin.y = (boxSize.height - size.height) / 2
    case .bottom:
        origin.y = boxSize.height - size.height
    default:
        origin.y = 0
    }
    return origin
}

private func computeFontSize(text: String, fontName: String, maximum: CGFloat, bounds: CGSize) -> CGFloat {
    guard text != "" else { return maximum }
    var size = maximum
    let iterations = 10

    for _ in 0..<iterations {
        let font = UIFont(name: fontName, size: size)!
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let wordWidths = words.map { word in
            word.size(withAttributes: [.font: font]).width
        }
        let maxWordWidth = wordWidths.max()!

        if maxWordWidth <= bounds.width {
            // ok, promising. Now see if the string fits in the box, constrained to width
            let attributed = NSAttributedString(string: text, attributes: [.font: font])
            let height = attributed
                .boundingRect(with: CGSize(width: bounds.width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil).height
            if height <= bounds.height {
                return size
            }
        }

        // didn't fit, so reduce the size and try again
        let newSize = round(size * 0.8)
        if newSize == size {
            return size // failed
        }
        size = newSize
    }

    return size
}

extension View {
    func paddedDrawingGroup(_ padding: CGFloat) -> some View {
        self
            .padding(padding)
            .drawingGroup()
            .padding(-padding)
    }

    @ViewBuilder func repeater(distance: CGSize, replicas: Int, brightnessStart: CGFloat, brightnessEnd: CGFloat) -> some View {
        let delta = CGSize(width: distance.width / CGFloat(replicas), height: distance.height / CGFloat(replicas))
        let brightnessDelta = (brightnessEnd - brightnessStart) / CGFloat(replicas)

        ZStack {
            ForEachWithRange(count: replicas) { index in
                self
                    .brightness(brightnessStart + brightnessDelta * CGFloat(index))
                    .offset(x: delta.width * CGFloat(index), y: delta.height * CGFloat(index))
            }
        }
    }
}

struct ForEachWithRange<C: View>: View {
    var count: Int
    @ViewBuilder var content: (Int) -> C

    var body: some View {
        ForEach(counters) { counter in
            content(counter.id)
        }
    }

    private struct Counter: Identifiable {
        let id: Int
    }

    private var counters: [Counter] {
        (0..<count).map { Counter(id: $0) }
    }
}

// Previews

struct FunTitleText_Previews: PreviewProvider {
    static var previews: some View {
        FunScreen {
            FunTitleText(text: "The Preamble to the Constitution")
                .padding(40)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
