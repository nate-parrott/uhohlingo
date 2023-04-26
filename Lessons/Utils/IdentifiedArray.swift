import Foundation

struct IdentifiedArray<T: Identifiable> {
    private var items: [T.ID: T] = [:]
    private var orderedIds = [T.ID]()

    init(_ array: [T]) {
        items = Dictionary(uniqueKeysWithValues: array.map { ($0.id, $0) })
        orderedIds = array.map { $0.id }
    }

    init() {}

    var array: [T] {
        orderedIds.compactMap { items[$0] }
    }

    var count: Int {
        items.count
    }

    // Subscript

    subscript(index: Int) -> T {
        get {
            items[orderedIds[index]]!
        }
        set {
            remove(id: orderedIds[index])
            orderedIds.insert(newValue.id, at: index)
            items[newValue.id] = newValue
        }
    }

    subscript(id: T.ID) -> T? {
        get {
            items[id]
        }
        set {
            if let newValue {
                append(newValue)
            } else {
                remove(id: id)
            }
        }
    }

    // Mutating

    mutating func append(_ item: T) {
        if items[item.id] != nil {
            remove(id: item.id)
        }
        orderedIds.append(item.id)
        items[item.id] = item
    }

    mutating func remove(id: T.ID) {
        if let index = orderedIds.firstIndex(of: id) {
            orderedIds.remove(at: index)
        }
        items[id] = nil
    }
}

extension IdentifiedArray: Sequence {
    func makeIterator() -> IndexingIterator<[T]> {
        array.makeIterator()
    }
}

extension IdentifiedArray: Equatable where T.ID: Equatable, T: Equatable {}

extension IdentifiedArray: Codable where T.ID: Codable, T: Codable {}
