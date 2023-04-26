import Foundation

struct ID<T>: Hashable, Codable {
    var rawValue: String

    init(_ value: String) {
        self.rawValue = value
    }

    static func assign() -> Self {
        return .init(UUID().uuidString)
    }
}

