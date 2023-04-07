import SwiftUI
import OpenAIStreamingCompletions

enum GenerateUnitError: Error {
    case noSuchLesson
    case badOutput
}

extension LessonStore {
    func generateUnits(forLessonWithId id: String) async throws {
        guard let lesson = model.lessons[id] else {
            throw GenerateUnitError.noSuchLesson
        }
        var prompt = Prompt()
        let count = 20
        prompt.append("""
You are creating a simple online course to teach a topic provided by the user.
When a topic is provided, output a lesson plan consisting of \(count) units that present a broad overview of the provided topic.
For each of the \(count) units, provide a 1-5 word name, and a concise one-sentence description. Each unit should be scoped such that its information can be learned in about 10 minutes.

Lesson content should reflect an inclusive, diverse perspective (e.g. history lessons should not be euro-centric.)

Provide lesson plans as valid JSON, encloses in code blocks (```). A lesson's JSON must conform to the following Typescript schema:
```
type Lesson = Unit[]
type Unit = {
    name: string
    description: string
}
```
```
""".trimmed, role: .system)

        prompt.append("""
For example, given a topic "Basic Spanish", expected output would consist of:
```
[
    { "name": "Greetings", "description": "Hello, goodbye and more" },
    { "name": "Names", "description": "Asking for and sharing people's names" },
    { "name": "Numbers", "description": "Numbers and counting." },
    ...etc
]
""".trimmed, role: .system)

        var userInput = "Topic: \(lesson.title)"
        if let prompt = lesson.prompt.nilIfEmpty {
            userInput += " (Extra instructions: \(prompt))"
        }
        prompt.append(userInput, role: .user)

        var lastResponse: String = ""

        for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt.packedPrompt(tokenCount: 2000), model: llmModel())) {

            if Task.isCancelled {
                return
            }
            
            if let units = partial.content.parsedAsUnits {
                LessonStore.shared.model.lessons[lesson.id]?.units = units
            }

            lastResponse = partial.content
        }

        if LessonStore.shared.model.lessons[lesson.id]!.units.count < 1 {
            print("Bad output: \(lastResponse)")
            throw GenerateUnitError.badOutput
        }
    }
}

private extension String {
    var parsedAsUnits: [Unit]? {
        let parts = components(separatedBy: "```")
        guard parts.count >= 2 else { return nil }
        let code = parts[1]

        for appendClosingBracket in [false, true] {
            let fullStr = appendClosingBracket ? code + "]" : code
            let data = fullStr.data(using: .utf8)!
            if let parsed = try? JSONDecoder().decode([Unit].self, from: data) {
                return parsed
            }
        }

        return nil
    }
}
