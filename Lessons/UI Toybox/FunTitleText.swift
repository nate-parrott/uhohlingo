import SwiftUI

struct FunTitleText: View {
    var text: Text

    var body: some View {
        ZStack {
            label
                .repeater(distance: CGSize(width: 3, height: 5), replicas: 3, brightnessStart: -0.1, brightnessEnd: -0.3)
                .paddedDrawingGroup(40)
                .drawingGroup()
//                .opacity(0.3)
            label
        }
    }

    @ViewBuilder private var label: some View {
        text
            .lineSpacing(12)
            .kerning(1)
            .textCase(.uppercase)
            .font(.system(size: 40, weight: .black))
            .italic()
            .foregroundColor(.blue)
//            .rotation3DEffect(.degrees(10), axis: (x: 1, y: -0.5, z: -1), perspective: 1)
    }
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
            FunTitleText(text: Text("The Preamble to the Constitution"))
                .padding(40)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
