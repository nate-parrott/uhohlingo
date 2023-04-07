import Foundation
import Combine
import SwiftUI

#if os(OSX)
      import AppKit
  #elseif os(iOS)
      import UIKit
  #endif

open class DataStore<Model: Equatable & Codable>: NSObject, ObservableObject {
    public struct TransactionMetadata: Equatable {
        let sender: String?
    }

    private var _model: Model {
        didSet { published = _model }
    }
    let persistenceKey: String?
    public let queue: DataStoreQueue

    public var model: Model {
        get {
            var val: Model!
            queue.runSync {
                val = self._model
            }
            return val
        }
        set(newVal) {
            queue.runSync {
                let prev = self._model
                // Run change handlers
                var final = newVal
                for handler in changeHandlers.values {
                    handler(prev, &final)
                }

                self._model = final
                self.published = final
            }
        }
    }

    @Published private var published: Model
    public var publisher: AnyPublisher<Model, Never> { $published.eraseToAnyPublisher() }

    public init(persistenceKey: String?, defaultModel: Model, queue: DataStoreQueue = .main) {
        _model = defaultModel
        self.queue = queue
        self.persistenceKey = persistenceKey
        self.published = defaultModel
        super.init()

        // Platform-specific notifications:
        #if os(OSX)
        let willResignActive = NSApplication.willResignActiveNotification
        let willTerminate = NSApplication.willTerminateNotification
        #elseif os(iOS)
            let willResignActive = UIApplication.willResignActiveNotification
            let willTerminate = UIApplication.willTerminateNotification
        #endif

        let startTime = CACurrentMediaTime()

        queue.run {
            var dataCount = 0

            let initialState: Model? = {
                for url in [self.persistentURL, self.localPathForInitialState].compactMap({ $0 }) {
                    do {
                        let data = try Data(contentsOf: url)
                        let state = try JSONDecoder().decode(Model.self, from: data)
                        dataCount = data.count
                        return state
                    } catch {
                        let name = self.persistenceKey ?? "<unknown>"
                        print("Failed to load \(name) datastore: \(error)")
                    }
                }
                return nil
            }()

            if let state = initialState {
                self._model = state
            }
            NotificationCenter.default.addObserver(self, selector: #selector(self.save), name: willResignActive, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.saveSync), name: willTerminate, object: nil)

            self.setup()

            let loadTime = CACurrentMediaTime() - startTime
            if let key = persistenceKey {
                let size = Int(round(Double(dataCount) / 1000))
                print("⏳ Loaded \(key) in \(loadTime)s (\(size)kb")
            }
            self.didCompleteInitialLoad(duration: loadTime)
        }
    }

    public func setup() {
        // for subclasses
    }

    public func modify(_ block: @escaping (inout Model) -> ()) {
        queue.run {
            var m = self._model
            block(&m)
            self._model = m
        }
    }

    @objc public func save() {
        queue.run {
            self._model = self.cleanup(model: self._model)
            if let key = self.persistenceKey {
                let processed = self.processModelBeforePersist(self._model)
                try! (try! JSONEncoder().encode(processed)).write(to: DataStore.persistentURL(key))
            }
        }
    }

    @objc func saveSync() {
        queue.runSync {
            self.save()
        }
    }

    public var persistentURL: URL? {
        if let key = self.persistenceKey {
            return Self.persistentURL(key)
        }
        return nil
    }

    static func persistentURL(_ key: String) -> URL {
        let appDir = "DataStores"
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent(appDir)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir.appendingPathComponent(key + ".json")
    }

    /// override this method to provide 'cleanup logic' to ensure that this data structure does not grow to an unbounded size.
    open func cleanup(model: Model) -> Model {
        return model
    }

    open func processModelBeforePersist(_ model: Model) -> Model {
        return model
    }

    open func didCompleteInitialLoad(duration: TimeInterval) {
        // override to do metrics
    }

    open var localPathForInitialState: URL? {
        return nil
    }

    public func getModel() async -> Model {
        return await withCheckedContinuation { continuation in
            self.queue.run {
                continuation.resume(returning: self.model)
            }
        }
    }

    public typealias ChangeHandler = (Model, inout Model) -> Void
    private var changeHandlers = [String: ChangeHandler]()
    public func addChangeHandler(id: String, handler: @escaping ChangeHandler) {
        self.changeHandlers[id] = handler
    }
    public func removeChangeHandler(id: String) {
        changeHandlers.removeValue(forKey: id)
    }
}

public struct DataStoreQueue {
    public let id: String
    public let queue: DispatchQueue

    public static func create(label: String = "Unnamed Queue", qos: DispatchQoS = .userInitiated) -> Self {
        let uuid = UUID().uuidString
        let id = "\(label):\(uuid)"
        return Self(id: id, queue: DispatchQueue(label: id, qos: qos, attributes: [], autoreleaseFrequency: .inherit, target: nil))
    }

    public static let main = Self(id: "main", queue: DispatchQueue.main)

    public var isCurrent: Bool {
        if id == "main" {
            return Thread.isMainThread
        }
        return DispatchQueue.currentQueueName() == id
    }

    public func assertCurrent() {
        assert(isCurrent)
    }

    public func run(_ block: @escaping () -> ()) {
        if isCurrent {
            block()
        } else {
            queue.async {
                block()
            }
        }
    }

    public func runSync(_ block: () -> ()) {
        if isCurrent {
            block()
        } else {
            if Self.main.isCurrent {
                print("😤 Synchronous queue hop from main thread!")
            }
            queue.sync {
                block()
            }
        }
    }
}

extension DispatchQueue {
    static func currentQueueName() -> String? {
        let name = __dispatch_queue_get_label(nil)
        return String(cString: name, encoding: .utf8)
    }
}

struct WithSnapshot<StateType: Equatable & Codable, Snapshot: Equatable, ViewContent: View>: View {
    var dataStore: DataStore<StateType>
    var snapshot: (StateType) -> Snapshot
    @ViewBuilder var viewContent: (Snapshot) -> ViewContent

    @State private var latestSnapshot: Snapshot?

    var body: some View {
        viewContent(effectiveSnapshot)
            .onReceive(dataStore.publisher.map(snapshot).removeDuplicates(), perform: { self.latestSnapshot = $0 })
    }

    private var effectiveSnapshot: Snapshot {
        latestSnapshot ?? self.snapshot(dataStore.model)
    }
}
