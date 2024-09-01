import SwiftUI
import ChatToys
//import OpenAIStreamingCompletions

enum GenerateUnitError: Error {
    case noSuchLesson
    case badOutput
}

extension CourseStore {
    func generateUnits(forCourseWithId id: Course.ID) async throws {
        guard let course = model.courses[id] else {
            throw GenerateUnitError.noSuchLesson
        }
        var prompt = Prompt()
        let count = Constants.unitCount
        let topicCount = Constants.topicsPerUnit

        // Struct for LLM output
        struct _Lesson: Equatable, Codable {
            var units: [_Unit]
            struct _Unit: Equatable, Codable {
                var n: String // name
                var t: [String] // topics
                var e: String // emoji
            }

            func asUnits(course: Course.ID) -> [Unit] {
                units.enumerated().compactMap { pair in
                    let (i, val) = pair
//                    guard let emoji = val.e, let topics = val.t else {
//                        return nil
//                    }
                    return .init(id: .init(course: course, unit: "\(i)"), name: val.n, topics: val.t, index: i, emoji: val.e, slideGroups: .init())
                }
            }
        }

        prompt.append("""
You are creating a simple online course to teach a topic provided by the user.
When a topic is provided, output a lesson plan consisting of \(count) units that present a broad overview of the provided topic.
For each of the \(count) units, provide a 1-5 word name and \(topicCount) concisely-named sub-topics. Each unit should be scoped such that its information can be learned in about 10 minutes.

Lesson content should reflect an inclusive, diverse perspective (e.g. history lessons should not be euro-centric.)

Provide lesson plans as valid JSON. A lesson's JSON must conform to the following Typescript schema:
```
interface Lesson {
    units: Unit[]
}
interface Unit {
    n: string // name
    t: [String] // topics: \(topicCount) topics that this unit will cover
    e: string // emoji: an emoji related to this unit
}
```
```
""".trimmed, role: .system)

        prompt.append("""
For example, given a topic "Basic Spanish", expected output would consist of:
```
{
    "units": [
        {"n": "Greetings", "t": ["Saying hello", "Saying goodbye", "Formal greetings", "Informal greetings"], "e": "🤝"},
        {"n": "Names", "t": ["Sharing your name", "Asking for someone's name"], "e": "🙋‍♂️"},
        {"n": "Numbers", "t": ["Counting", "Money"], "e": "💸"},
        ...etc
    ]
}
```
""".trimmed, role: .system)

        var userInput = "Topic: \(course.title)"
        if let prompt = course.extraInstructions.nilIfEmpty {
            userInput += " (Extra instructions: \(prompt))"
        }
        prompt.append(userInput, role: .user)
        prompt.append("Your JSON:", role: .system)

        func process(response: _Lesson, partial: Bool) {
            var units = response.asUnits(course: id)
            if partial, units.count > 0 {
                units.removeLast()
            }
            CourseStore.shared.modify { state in
                for unit in units {
                    if state.courses[course.id]?.units[unit.id] == nil {
                        state.courses[course.id]?.units[unit.id] = unit
                    }
                }
            }
        }

        let llm = try ModelChoice.current.llm(json: true)
        let messages = prompt.packedPrompt(tokenCount: 3000)
        var lastResponse: _Lesson?
        for try await partial in llm.completeStreamingWithJSONObject(prompt: messages, type: _Lesson.self) {
            if Task.isCancelled {
                return
            }
            lastResponse = partial
            process(response: partial, partial: true)
        }
        if let lastResponse {
            process(response: lastResponse, partial: false)
        }

        if let finalUnitCount = CourseStore.shared.model.courses[course.id]?.units.count, finalUnitCount < 1 {
//            print("Bad output: \(lastResponse)")
            throw GenerateUnitError.badOutput
        }
    }
}
