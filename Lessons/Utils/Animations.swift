import SwiftUI

extension Animation {
    static func niceDefault(duration: TimeInterval) -> Animation {
        .timingCurve(0.25, 0.1, 0.25, 1, duration: duration)
    }
    static var niceDefault: Animation { .niceDefault(duration: 0.3) }
}
//
//extension AnyTransition {
//    static var wipeAway: AnyTransition {
//        .modifier(active: WipeMask(revealProgress: 0), identity: WipeMask(revealProgress: 1))
//    }
//}
