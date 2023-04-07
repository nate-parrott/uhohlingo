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

extension LessonStore {
    func ensureQuizGenerated(lessonId: String, unitIndex: Int) async throws {
        guard let lesson = await getModel().lessons[lessonId] else { return }
        guard let unit = lesson.units.get(unitIndex) else { return }
        let targetQuestionCount = 5
        let existingQuestionCount = (unit.quizQuestions ?? []).count
        if existingQuestionCount < targetQuestionCount {
            try await generateQuestions(review: false, count: targetQuestionCount - existingQuestionCount, kind: .multipleChoice, lesson: lesson, unitIndex: unitIndex)
        }
    }

    func generateQuestions(review: Bool /* else quiz */, count: Int, kind: QuestionKind, lesson: Lesson, unitIndex: Int) async throws {
        guard let unit = lesson.units.get(unitIndex) else {
            throw GenerateQuestionsError.noSuchUnit
        }

        if unit.slides?.count ?? 0 == 0 {
            throw GenerateQuestionsError.noInfo
        }

        var prompt = Prompt()
        prompt.append("""
You are creating a series of quiz questions for an online course.

COURSE: \(lesson.title)
EXTRA COURSE INSTRUCTIONS: \(lesson.prompt.nilIfEmpty ?? "None")
CURRENT UNIT: \(unit.name)
UNIT DESCRIPTION: \(unit.description)
""".trimmed, role: .system, priority: 100)

        prompt.append("Here are the slides for this unit:", role: .system, priority: 20)
        let slideContent = (unit.slides ?? []).map(\.markdown).joined(separator: "\n====\n")
        prompt.append(slideContent, role: .system, priority: 10, canTruncateToLength: 200)

        // TODO: Show previous units

        prompt.append("""
Now, generate \(count) \(kind.desc) quiz questions covering the information above. Output each question on its own line as a valid JSON string, with no additional text. (Put differently, each line should begin with { and end with })

\(kind.instructions)
""".trimmed, role: .system, priority: 120)

        var lastResponse: String = ""
        var added = 0
        let originalQuestions = (review ? unit.reviewQuestions : unit.quizQuestions) ?? []

        for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt.packedPrompt(tokenCount: 2000), model: llmModel(), max_tokens: 2000, temperature: 0.1)) {
            let questions = partial.content.components(separatedBy: .newlines)
                .compactMap { $0.parseAsQuestion(kind: kind) }
            added = questions.count
            modifyUnit(lessonId: lesson.id, unitIndex: unitIndex) { unit in
                if review {
                    unit.reviewQuestions = originalQuestions + questions
                } else {
                    unit.quizQuestions = originalQuestions + questions
                }
            }

            lastResponse = partial.content
        }

        if added == 0 {
            print("Failed to generate questions. Response: \(lastResponse)")
            throw GenerateQuestionsError.badResponse
        }
    }
}

private extension String {
    func parseAsQuestion(kind: QuestionKind) -> Question? {
        switch kind {
        case .multipleChoice:
            if let multi = try? JSONDecoder().decode(Question.MultipleChoice.self, from: Data(utf8)) {
                return Question(multipleChoice: multi)
            }
        }
        return nil
    }
}
