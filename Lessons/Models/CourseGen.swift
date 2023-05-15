import SwiftUI
import OpenAIStreamingCompletions

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
        prompt.append("""
You are creating a simple online course to teach a topic provided by the user.
When a topic is provided, output a lesson plan consisting of \(count) units that present a broad overview of the provided topic.
For each of the \(count) units, provide a 1-5 word name and \(topicCount) concisely-named sub-topics. Each unit should be scoped such that its information can be learned in about 10 minutes.

Lesson content should reflect an inclusive, diverse perspective (e.g. history lessons should not be euro-centric.)

Provide lesson plans as valid JSON, encloses in code blocks (```). A lesson's JSON must conform to the following Typescript schema:
```
type Lesson = Unit[]
type Unit = {
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
[
{"n": "Greetings", "t": ["Saying hello", "Saying goodbye", "Formal greetings", "Informal greetings"], "e": "🤝"},
{"n": "Names", "t": ["Sharing your name", "Asking for someone's name"], "e": "🙋‍♂️"},
{"n": "Numbers", "t": ["Counting", "Money"], "e": "💸"},
    ...etc
]
""".trimmed, role: .system)

        var userInput = "Topic: \(course.title)"
        if let prompt = course.extraInstructions.nilIfEmpty {
            userInput += " (Extra instructions: \(prompt))"
        }
        prompt.append(userInput, role: .user)

        var lastResponse: String = ""

        for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt.packedPrompt(tokenCount: 2000), model: llmModel())) {

            if Task.isCancelled {
                return
            }
            
            if let units = partial.content.parsedAsUnits(courseId: id) {
                CourseStore.shared.modify { state in
                    for unit in units {
                        if state.courses[course.id]?.units[unit.id] == nil {
                            state.courses[course.id]?.units[unit.id] = unit
                        }
                    }
                }
//                CourseStore.shared.model.courses[course.id]?.units = Array(units.values)
            }

            lastResponse = partial.content
        }

        if CourseStore.shared.model.courses[course.id]!.units.count < 1 {
            print("Bad output: \(lastResponse)")
            throw GenerateUnitError.badOutput
        }
    }
}

private extension String {
    func parsedAsUnits(courseId: Course.ID) -> [Unit]? {
        struct PartialUnit: Codable {
            var n: String // name
            var t: [String] // title
            var e: String // emoji
        }

        let parts = components(separatedBy: "```")
        guard parts.count >= 2 else { return nil }
        let code = parts[1]

        for appendClosingBracket in [false, true] {
            let fullStr = appendClosingBracket ? code + "]" : code
            let data = fullStr.data(using: .utf8)!
            if let parsed = try? JSONDecoder().decode([PartialUnit].self, from: data) {
                return parsed.enumerated().map { pair in
                    let (index, unit) = pair
                    return .init(id: .init(course: courseId, unit: "\(index)"), name: unit.n, topics: unit.t, index: index, emoji: unit.e, slideGroups: .init())
                }
            }
        }

        return nil
    }
}
