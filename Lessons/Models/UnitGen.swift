import Foundation
import OpenAIStreamingCompletions

enum UnitContentGenerationError: Error {
    case noSuchUnit
    case badOutput
}
//
//extension LessonStore {
//    func generateUnitContentIfNeeded(lesson: Lesson, unitIndex: Int) async throws {
//        guard let unit = lesson.units.get(unitIndex) else {
//            throw UnitContentGenerationError.noSuchUnit
//        }
//
//        if unit.slides?.count ?? 0 > 0 {
//            return // done
//        }
//
//        var prompt = Prompt()
//        prompt.append("""
//You are generating a casual, concise and fact-packed online lesson.
//
//Right now, you will be asked to generate a set of engaging slides, teaching the reader about a particular lesson in the course in 5 minutes or less.
//
//COURSE: \(lesson.title)
//EXTRA COURSE INSTRUCTIONS: \(lesson.prompt.nilIfEmpty ?? "None")
//CURRENT UNIT: \(unit.name)
//UNIT DESCRIPTION: \(unit.description)
//""", role: .system, priority: 100)
//
//        prompt.appendUnitDescriptions(forLesson: lesson, basePriority: 10)
//
//        prompt.append("""
//Now, please generate a series of slides, beginning with an outline slide, and 2-4 informational slides.
//Each slide should include no more than 80 words.
//
//Favor concise language and facts over opinion. Aim to inform, not to preach.
//
//Your response should include all slides, and only the slides. Do not include the word 'slide' or the slide index in slide titles. Slides are written in standard Markdown.
//
//Outline slides should contain:
//- A header (# Example)
//- 1-2 sentences introducing the unit
//- A list, titled something like 'Overview', outlining the titles of the following slides.
//
//Informational slides should contain, in order:
//- A header (# Example)
//- If possible, a search term that would generate a specific, relevant image relating to the slide's content. Provide the search term using this special syntax: (IMAGE SEARCH: example query). One per slide, at most.
//- The informational content of the slide
//  - Include tables, lists and formatting as appropriate.
//  - You may link to Wikipedia, but nowhere else.
//  - Do not include inline images. For images, use only the image syntax above.
//  - For history-related courses, slides may include timelines, key people, vocabulary sections or other helpful content.
//  - For language-related courses, slides may include tables of key vocabulary, grammatical concepts, sample conversations or other helpful content.
//- To separate one slide from the next, write "====" on its own line.
//""".trimmed, role: .system, priority: 150)
//
//        prompt.append("""
//SLIDES FOR \(lesson.title) — \(unit.name) (\(unit.description):
//""", role: .system, priority: 80)
//
//        var lastResponse: String = ""
//
//        for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt.packedPrompt(tokenCount: 2000), model: llmModel(), max_tokens: 2000, temperature: 0.1)) {
//
//            if Task.isCancelled {
//                return
//            }
//
//            if let slides = partial.content.parsedAsSlides {
//                LessonStore.shared.model.lessons[lesson.id]?.units[unitIndex].slides = slides
//            }
//
//            lastResponse = partial.content
//        }
//
//        if (LessonStore.shared.model.lessons[lesson.id]!.units.get(unitIndex)?.slides?.count ?? 0) < 1 {
//            print("Bad output: \(lastResponse)")
//            throw UnitContentGenerationError.badOutput
//        }
//    }
//}
//
///* struct LessonSlide: Equatable, Codable {
//    var imageQuery: String?
//    var content: String
//} */
//
//extension Prompt {
//    mutating func appendUnitDescriptions(forLesson lesson: Lesson, prefix: String = "As a reminder, the course's units are:", basePriority: Double = 10) {
//        append(prefix, role: .system, priority: basePriority)
//        for (i, unit) in lesson.units.enumerated() {
//            append(
//                "\(i+1). \(unit.name) (\(unit.description))",
//                role: .system,
//                priority: basePriority + Double(i) * 0.1,
//                canTruncateToLength: 20
//            )
//        }
//    }
//}
//
//extension Lesson {
//    var unitDescriptionsList: String {
//        // return enumerated list
//        return units.enumerated()
//            .map { "\($0+1). \($1.name) (\($1.description))" }
//            .joined(separator: "\n")
//
//    }
//}
//
//extension String {
//    var parsedAsSlides: [LessonSlide]? {
//        let slides = self.components(separatedBy: "====")
//        return slides.compactMap(\.parseAsSingleSlide).filter { $0.markdown.trimmed.count > 0 }
//    }
//
//    var parseAsSingleSlide: LessonSlide? {
//        return .init(markdown: self) // TODO: parse image
//    }
//}
