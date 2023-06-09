import Foundation

struct ProgressState: Equatable, Codable {
    struct Answer: Equatable, Codable {
        var question: Question
        var grade: Double // 0..1
        var answer: String
    }

    var quizResponses = [Question.ID: Answer]()
}

class ProgressStore: DataStore<ProgressState> {
    static let shared = ProgressStore(persistenceKey: "Progress2", defaultModel: .init())
}
