import SwiftUI
import OpenAIStreamingCompletions

enum QuestionKind {
    case multipleChoice

    var desc: String {
        switch self {
        case .multipleChoice: return "multiple choice"
        }
    }

    var instructions: String {
        switch self {
        case .multipleChoice:
            return """
Each multiple choice question should be structured in this form:
{ "question": "Translate 'Where is the library?'", "correct": "¿Dónde está la biblioteca?", "incorrect": ["¿Cuánto cuesta?", "¿Cómo estás?", "¿Qué hora es?"] }
""".trimmed
        }
    }
}

enum GenerateQuestionsError: Error {
    case noSuchUnit
    case noInfo
    case badResponse
}
