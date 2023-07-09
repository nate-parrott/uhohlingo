import Foundation
import OpenAIStreamingCompletions

//struct Lesson: Equatable, Codable, Identifiable {
//    var id: String
//    var date: Date
//    var title: String
//    var prompt: String
//    var units: [Unit]
//}
//
//struct Unit: Equatable, Codable {
//    var name: String
//    var description: String
//
//    var slides: [LessonSlide]?
//    var reviewQuestions: [Question]?
//    var quizQuestions: [Question]?
//}
//struct LessonSlide: Equatable, Codable {
//    var markdown: String
//    var imageQuery: String?
//}

extension ChatStore {
    func send(message: ChatMessage, toThreadForUnit unitID: Unit.ID) async throws {
        let coursesState = await CourseStore.shared.getModel()
        guard let course = coursesState.courses[unitID.course],
              let unit = course.units[unitID],
              let unitIndex = course.sortedUnits.firstIndex(of: unit)
        else { return }

        // First we'll append the user message, and then generate a response
        modify { state in
            state.updateThread(unitID: unitID) { thread in
                thread.messages.append(message)
                thread.typing = true
            }
        }

        defer {
            modify { state in
                state.updateThread(unitID: unitID) { thread in
                    thread.typing = false
                }
            }
        }

        var prompt = Prompt()

        let intro = """
You are a helpful, patient and insightful teacher who is helping the user with an online course.

The course is titled '\(course.title)'.
""".trimmed
//        if let instr = course.prompt.nilIfEmpty {
//            intro += " Additional instructions about the course: '\(instr)'"
//        }
        prompt.append(intro, role: .system, priority: 100)


        let unitTitlesUpToAndIncludingThis = course.sortedUnits.prefix(through: unitIndex).map(\.name)
        let recap = """
This is Unit #\(unitIndex + 1). So far, the course has covered these units:
\(unitTitlesUpToAndIncludingThis.joined(separator: ", "))
"""
        prompt.append(recap, role: .system, priority: 80, canTruncateToLength: 100)

        let unitInfo = """
This conversation concerns the unit '\(unit.name)', which covers these topics: '\(unit.topics.joined(separator: ", "))'.
"""
        prompt.append(unitInfo, role: .system, priority: 90)

        // TODO: Fetch the current topic
//        if let slides = unit.concatSlidesMarkdown {
//            prompt.append("Here is a sample of the content of the unit, which the user will be asking about:\n\(slides)", role: .system, priority: 50, canTruncateToLength: 400)
//        }
//        prompt.appendTopicContent(forCourse: <#T##Course#>, unit: <#T##Unit#>, topic: <#T##String#>, priority: <#T##Double#>)

        prompt.append("Conversation:", role: .system, priority: 100)

        let previousMessages = await getModel().threads[unitID]?.messages ?? []
        for prevMessage in previousMessages.reversed().enumerated().reversed() {
            let (distFromEnd, message) = prevMessage
            let priority: Double = distFromEnd <= 2 ? 85 : 40 - Double(distFromEnd) // newer messages have lower priorities
            prompt.appendMessage(message, priority: priority, canOmit: distFromEnd > 2, canTruncate: 200)
        }

        let packed = prompt.packedPrompt(tokenCount: 2400)
        print("Prompt:\n\(packed.asConversationString)")

        // Now, use the prompt to generate a completion:
        for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: packed, model: llmModel())) {
            modify { state in
                state.updateThread(unitID: unitID) { thread in
                    if let lastMsg = thread.messages.last, lastMsg.isFromAssistant {
                        _ = thread.messages.removeLast()
                    }
                    thread.messages.append(.assistantSaid(partial.content))
                }
            }
        }
    }
}

//enum ChatMessage: Equatable, Codable {
//    case userSaid(String)
//    case userWantsExplanation(ProgressState.Answer)
//    case userWantsToPractice
//    case assistantSaid(String)
//}

extension Prompt {
    mutating func appendMessage(_ message: ChatMessage, priority: Double, canOmit: Bool, canTruncate: Int?) {
        let omissionMsg = canOmit ? "[Older messages hidden]" : nil
        switch message {
        case .assistantSaid(let text):
            append(text, role: .assistant, priority: priority, canTruncateToLength: canTruncate, canOmit: canOmit, omissionMessage: omissionMsg)
        case .userSaid(let text):
            append(text, role: .user, priority: priority, canTruncateToLength: canTruncate, canOmit: canOmit, omissionMessage: omissionMsg)
        case .userWantsExplanation(let answer):
            let p = """
The user is asking for an explanation about a quiz question they answered.
The question, in JSON form: \(answer.question.encodedAsJSONString)
The user's answer: \(answer.answer).
Explain the question. If the user was incorrect, explain why. Refer to the user as 'you.' Remember to be friendly, patient and concise!
"""
            append(p, role: .system, priority: priority, canTruncateToLength: canTruncate, canOmit: canOmit, omissionMessage: omissionMsg)
            append(answer.grade == 0 ? "Why was this incorrect?" : "Explain this to me.", role: .user, priority: priority, canTruncateToLength: canTruncate, canOmit: canOmit, omissionMessage: omissionMsg)
        case .userWantsToPractice:
            append("I'd like to practice this unit. Give me some quiz questions!", role: .user, priority: priority, canTruncateToLength: canTruncate, canOmit: canOmit, omissionMessage: omissionMsg)
        }
    }
}

//extension Unit {
//    var concatSlidesMarkdown: String? {
//        guard let slides else { return nil }
//        if slides.isEmpty { return nil }
//        return slides.map(\.markdown).joined(separator: "\n\n")
//    }
//}

extension ChatMessage {
    var isFromAssistant: Bool {
        switch self {
        case .assistantSaid: return true
        case .userSaid, .userWantsExplanation, .userWantsToPractice: return false
        }
    }
}
