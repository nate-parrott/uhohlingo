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
    name: string
    topics: [String] // \(topicCount) topics that this unit will cover
}
```
```
""".trimmed, role: .system)

        prompt.append("""
For example, given a topic "Basic Spanish", expected output would consist of:
```
[
    { "name": "Greetings", "topics": ["Saying hello", "Saying goodbye", "Formal greetings", "Informal greetings" },
    { "name": "Names", "topics": ["Sharing your name", "Asking for someone's name"] },
    { "name": "Numbers", "topics": ["Counting", "Money"] },
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
                        state.courses[course.id]?.units[unit.id] = unit
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
            var name: String
            var topics: [String]
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
                    return .init(id: .init(course: courseId, unit: "\(index)"), name: unit.name, topics: unit.topics, index: index, slideGroups: .init())
                }
            }
        }

        return nil
    }
}
