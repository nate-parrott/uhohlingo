import Foundation

extension Array {
    func get(_ index: Int) -> Element? {
        if self.count > index {
            return self[index]
        } else {
            return nil
        }
    }
}

extension Sequence where Element: Hashable {
    var asSet: Set<Element> {
        Set(self)
    }
}
