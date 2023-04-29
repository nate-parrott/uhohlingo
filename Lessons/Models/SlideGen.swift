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
        case .topic(let topic):
            return try generateTopicSlideGroup(unitID: unitID, groupID: groupID, topic: topic)
        case .conclusion:
            var group = SlideGroup(slides: .init(), id: .conclusion, completedGenerating: true)
            group.slides.append(.init(id: Slide.SlideID(unit: unitID, group: groupID, slide: "text"), content: .title(.init(title: "That’s it!"))))
            return AsyncStream(just: group)
        }
    }

    func generateTopicSlideGroup(unitID: Unit.ID, groupID: SlideGroup.ID, topic: String) throws -> AsyncStream<SlideGroup> {
        guard let course = model.courses[unitID.course], let unit = course.units[unitID] else {
            throw UnitContentGenerationError.noSuchUnit
        }

        return AsyncStream { continuation in
            Task {
                var group = SlideGroup(slides: .init(), id: groupID, completedGenerating: false)

                let titleSlide = Slide(
                    id: .init(unit: unitID, group: groupID, slide: "title"),
                    content: .title(TitleSlideContent(title: topic, emoji: unit.emoji))
                )
                group.slides.append(titleSlide)
                continuation.yield(group)

                for await info in try self.generateInfoSlideContent(unitID: unitID, topic: topic) {
                    let infoSlide = Slide(id: .init(unit: unitID, group: groupID, slide: "info"), content: .info(info))
                    group.slides.append(infoSlide) // if an item with same ID already exists, this will remove first
                    continuation.yield(group)
                    if Task.isCancelled { return }
                }

                for await question in try self.generateQuestions(unitID: unitID, topic: topic, count: Constants.questionsPerTopic) {
                    let questionSlide = Slide(id: .init(unit: unitID, group: groupID, slide: "question-\(question.id.rawValue)"), content: .question(question))
                    group.slides.append(questionSlide)
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

//        let extraInstructions = course.extraInstructions != "" ? "Extra instructions about the course: \(course.extraInstructions)" : ""

        return AsyncStream { continuation in
            Task {
                var prompt = Prompt()
                prompt.appendIntroduction(forCourse: course, unit: unit, topic: topic, priority: 100)
                prompt.appendListOfUnits(forCourse: course, basePriority: 10)

                prompt.append("""
        Now, please generate a short slide providing useful, concise, and engaging information about the current topic, '\(topic)', part of the '\(unit.name)' unit of the '\(course.title)' course.

        Favor concise language and facts over opinion. Aim to inform and engage, not to preach. Make sure to include only the most important information about the topic. Imagine that this slide is the only information a person will ever learn about this topic.

        Output rules:
        - Format output in Markdown.
        - Only include the slide's Markdown. No additional output.
        - Start with a header (# Example)
        - Then, 1 sentence introducing the topic.
        - Then, 1 item (paragraph, list or table) providing the most important and interesting information about the topic.
          - Use bulleted lists when appropriate (for example, for describing key facts, people or characteristics)
          - Use tables when appropriate (fore example, key vocabulary or concepts, or compare-and-constrast information.)
          - Include tables, lists and formatting as appropriate.
        - You may link to Wikipedia, but nowhere else.
        """, role: .system, priority: 150)

                prompt.append("""
        SLIDE FOR \(course.title) > \(unit.name) > (\(topic):
        """, role: .system, priority: 200)

                var lastContent: InfoSlideContent?
                for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt.packedPrompt(tokenCount: 2000), model: llmModel(), max_tokens: 2000, temperature: 0.1)) {
                    if Task.isCancelled { return }
                    let content = InfoSlideContent(markdown: partial.content.trimmed, generationInProgress: true)
                    lastContent = content
                    continuation.yield(content)
                }
                if let lastContent {
                    continuation.yield(.init(markdown: lastContent.markdown, generationInProgress: false))
                }
                continuation.finish()
            }
        }
    }

    func generateQuestions(unitID: Unit.ID, topic: String, count: Int) throws -> AsyncStream<Question> {
        guard let course = model.courses[unitID.course], let unit = course.units[unitID] else {
            throw UnitContentGenerationError.noSuchUnit
        }
        return AsyncStream { continuation in
            Task {
                var prompt = Prompt()
                prompt.appendIntroduction(forCourse: course, unit: unit, topic: topic, priority: 100)
                prompt.appendListOfUnits(forCourse: course, basePriority: 10)
                prompt.appendTopicContent(forCourse: course, unit: unit, topic: topic, priority: 20)

                prompt.append("""
        Now, please write a series of \(count) quiz questions related to this topic.


        JSON schema for each question, in Typescript:
        type Question = { "multipleChoice": MultipleChoice }
        type MultipleChoice = { question: string, correct: string, incorrect: string[] }

        Important rules for writing questions:
        - Output each question on its own line, in JSON form, as type `Question` in the schema above.
        - Do not include any additional text on each line besides the JSON string. (This means each line should begin with { and end with })
        - Questions should test knowledge introduced in this topic, but may depend on knowledge from previous units.
        - Questions should be of moderate difficulty.
        - Keep it concise, engaging and fun.

        Some examples of questions for a hypothetic unit about Spanish:
        { "multipleChoice": { "question": "Translate 'Where is the library?'", "correct": "¿Dónde está la biblioteca?", "incorrect": ["¿Cuánto cuesta?", "¿Cómo estás?", "¿Qué hora es?"] } }

        """, role: .system, priority: 150)

                prompt.append("\(count) questions about'\(topic)', part of the '\(unit.name)' unit of the '\(course.title)' course:", role: .system, priority: 200)

                var seenQuestions = Set<Question.ID>()

                for await partial in try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt.packedPrompt(tokenCount: 2000), model: llmModel(), max_tokens: 2000, temperature: 0.1)) {
                    let questions = partial.content.components(separatedBy: .newlines)
                        .enumerated()
                        .compactMap { pair in
                            let (index, line) = pair
                            let id = "\(course.id.rawValue)/\(unitID.unit)/\(topic)/\(index)"
                            return line.parseAsQuestion(id: id)
                        }
                    for question in questions {
                        if !seenQuestions.contains(question.id) {
                            seenQuestions.insert(question.id)
                            continuation.yield(question)
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
}

extension Unit {
    var necessarySlideGroupIDs: [SlideGroup.ID] {
        var ids: [SlideGroup.ID] = topics.map { SlideGroup.ID.topic($0) }
        ids.append(.conclusion)
        return ids
    }

    var completeSlideGroupIDs: [SlideGroup.ID] {
        slideGroups.filter(\.completedGenerating).map(\.id)
    }

    var remainingSlideGroupIDsToGenerate: [SlideGroup.ID] {
        let completed = completeSlideGroupIDs.asSet
        return necessarySlideGroupIDs.filter { !completed.contains($0) }
    }
}

extension Prompt {
    mutating func appendIntroduction(forCourse course: Course, unit: Unit, topic: String, priority: Double) {
        let topicsJoined = unit.topics.joined(separator: ", ")

        append("""
You are generating a casual, concise and fact-packed online course.
COURSE TITLE: \(course.title)
EXTRA COURSE INSTRUCTIONS: \(course.extraInstructions.nilIfEmpty ?? "None")
CURRENT UNIT: \(unit.name)
UNIT TOPICS: \(topicsJoined)
CURRENT TOPIC: \(topic)
""", role: .system, priority: 100)
    }

    mutating func appendListOfUnits(forCourse course: Course, prefix: String = "As a reminder, the course's units are:", basePriority: Double) {
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

    mutating func appendTopicContent(forCourse course: Course, unit: Unit, topic: String, prefix: String = "Here is the content the learner was taught for this topic:", priority: Double) {
        if let infoSlide = unit.infoSlide(forTopic: topic) {
            append(prefix + "\n" + infoSlide.markdown, role: .system, priority: priority, canTruncateToLength: 200)
        }
    }
}

extension Unit {
    func infoSlide(forTopic topic: String) -> InfoSlideContent? {
        guard let group = slideGroups[.topic(topic)] else {
            return nil
        }
        for slide in group.slides {
            if case .info(let content) = slide.content {
                return content
            }
        }
        return nil
    }
}

private extension String {
    func parseAsQuestion(id: String) -> Question? {
        struct JsonQuestion: Codable {
            var multipleChoice: Question.MultipleChoice?
        }

        guard let root = try? JSONDecoder().decode(JsonQuestion.self, from: Data(utf8)) else {
            return nil
        }

        if let mc = root.multipleChoice {
            return .init(id: .init(id), multipleChoice: mc)
        }

        return nil
    }
}
