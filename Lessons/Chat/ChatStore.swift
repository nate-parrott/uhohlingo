import Foundation

enum ChatMessage: Equatable, Codable {
    case userSaid(String)
    case userWantsExplanation(ProgressState.Answer)
    case userWantsToPractice
    case assistantSaid(String)
}

struct ChatState: Equatable, Codable {
    struct Thread: Equatable, Codable {
        var messages: [ChatMessage]
        var typing: Bool
    }

    var threads = [UnitID: Thread]()
}

extension ChatState {
    mutating func updateThread(unitID: UnitID, modifier: (inout Thread) -> Void) {
        var thread = threads[unitID] ?? .init(messages: [], typing: false)
        modifier(&thread)
        threads[unitID] = thread
    }
}

class ChatStore: DataStore<ChatState> {
    static let shared = ChatStore(persistenceKey: "Chat", defaultModel: .init())
}
