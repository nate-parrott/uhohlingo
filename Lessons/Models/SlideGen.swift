import Foundation
import OpenAIStreamingCompletions

enum UnitContentGenerationError: Error {
    case noSuchUnit
    case badOutput
}

extension CourseStore {
    func generateSlidesIfNeeded(unitID: Unit.ID) async throws {
        // TODO: Make sure multiple writers are not generating this unit at the same time
        guard let courseOriginal = model.courses[unitID.course], let unitOriginal = courseOriginal.units[unitID] else {
            throw UnitContentGenerationError.noSuchUnit
        }
        let generateGroupIDs = unitOriginal.remainingSlideGroupIDsToGenerate
        for groupID in generateGroupIDs {
            for await partial in try generateSlideGroup(unitID: unitID, groupID: groupID) {
                modifyUnit(unitID: unitID) { unit in
                    unit.slideGroups.append(partial)
                }
                if Task.isCancelled { return }
            }
            modifyUnit(unitID: unitID) { unit in
                unit.slideGroups[groupID]?.completedGenerating = true
            }
        }
    }

    func generateSlideGroup(unitID: Unit.ID, groupID: SlideGroup.ID) throws -> AsyncStream<SlideGroup> {
        switch groupID {
        case .topic(let topic): return try generateTopicSlideGroup(unitID: unitID, groupID: groupID, topic: topic)
        }
    }

    func generateTopicSlideGroup(unitID: Unit.ID, groupID: SlideGroup.ID, topic: String) throws -> AsyncStream<SlideGroup> {
        return AsyncStream { continuation in
            Task {
                var group = SlideGroup(slides: .init(), id: groupID, completedGenerating: false)

                let titleSlide = Slide(
                    id: .init(unit: unitID, group: groupID, slide: "title"),
                    content: .title(TitleSlideContent(title: topic))
                )
                group.slides.append(titleSlide)
                continuation.yield(group)

                for await info in try self.generateInfoSlideContent(unitID: unitID, topic: topic) {
                    let infoSlide = Slide(id: .init(unit: unitID, group: groupID, slide: "info"), content: .info(info))
                    group.slides.append(infoSlide) // if an item with same ID already exists, this will remove first
                    continuation.yield(group)
                    if Task.isCancelled { return }
                }

                continuation.finish()
            }
        }
    }

    func generateInfoSlideContent(unitID: Unit.ID, topic: String) throws -> AsyncStream<InfoSlideContent> {
        guard let course = model.courses[unitID.course], let unit = course.units[unitID] else {
            throw UnitContentGenerationError.noSuchUnit
        }
        let topicsJoined = unit.topics.joined(separator: ", ")

//        let extraInstructions = course.extraInstructions != "" ? "Extra instructions about the course: \(course.extraInstructions)" : ""

        return AsyncStream { continuation in
            Task {
                var prompt = Prompt()
                prompt.append("""
        You are generating a casual, concise and fact-packed online course.
        COURSE TITLE: \(course.title)
        EXTRA COURSE INSTRUCTIONS: \(course.extraInstructions.nilIfEmpty ?? "None")
        CURRENT UNIT: \(unit.name)
        UNIT TOPICS: \(topicsJoined)
        CURRENT TOPIC: \(topic)
        """, role: .system, priority: 100)

                prompt.appendUnitDescriptions(forCourse: course, basePriority: 10)

                prompt.append("""
        Now, please generate a short slide providing useful, concise, and engaging information about the current topic, '\(topic)', part of the '\(unit.name)' unit of the '\(course.title)' course.

        Favor concise language and facts over opinion. Aim to inform and engage, not to preach. Make sure to include only the most important information about the topic. Imagine that this slide is the only information a person will ever learn about this topic.

        Output rules:
        - Format output in Markdown.
        - Only include the slide's Markdown. No additional output.
        - Start with a header (# Example)
        - Then, 1-2 sentences introducing the topic.
        - Then, 1-3 items (paragraphs, lists or tables) providing the most important and interesting information about the topic.
          - Use bulleted lists when appropriate (for example, for describing key facts, people or characteristics)
          - Use tables when appropriate (fore example, key vocabulary or concepts, or compare-and-constrast information.)
          - Include tables, lists and formatting as appropriate.
        - You may link to Wikipedia, but nowhere else.
        """.trimmed, role: .system, priority: 150)

                prompt.append("""
        SLIDE FOR \(course.title) > \(unit.name) > (\(topic):
        """, role: .system, priority: 200)

                for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt.packedPrompt(tokenCount: 2000), model: llmModel(), max_tokens: 2000, temperature: 0.1)) {
                    if Task.isCancelled { return }
                    continuation.yield(InfoSlideContent(markdown: partial.content.trimmed))
                }
                continuation.finish()
            }
        }
    }
}

extension Unit {
    var necessarySlideGroupIDs: [SlideGroup.ID] {
        topics.map { SlideGroup.ID.topic($0) }
    }

    var completeSlideGroupIDs: [SlideGroup.ID] {
        slideGroups.filter(\.completedGenerating).map(\.id)
    }

    var remainingSlideGroupIDsToGenerate: [SlideGroup.ID] {
        let completed = completeSlideGroupIDs.asSet
        return necessarySlideGroupIDs.filter { !completed.contains($0) }
    }
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

extension Prompt {
    mutating func appendUnitDescriptions(forCourse course: Course, prefix: String = "As a reminder, the course's units are:", basePriority: Double = 10) {
        append(prefix, role: .system, priority: basePriority)
        for (i, unit) in course.sortedUnits.enumerated() {
            append(
                "\(i+1). \(unit.name) (\(unit.description))",
                role: .system,
                priority: basePriority + Double(i) * 0.1,
                canTruncateToLength: 20
            )
        }
    }
}
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
