import Foundation

struct UnitID: Equatable, Codable, Hashable {
    var lessonId: String
    var unitIndex: Int
}

struct Lesson: Equatable, Codable, Identifiable {
    var id: String
    var date: Date
    var title: String
    var prompt: String
    var units: [Unit]
}

struct Unit: Equatable, Codable {
    var name: String
    var description: String

    var slides: [LessonSlide]?
    var reviewQuestions: [Question]?
    var quizQuestions: [Question]?
}

struct LessonSlide: Equatable, Codable {
    var markdown: String
    var imageQuery: String?
}

struct Question: Equatable, Codable, Hashable {
    struct MultipleChoice: Equatable, Codable, Hashable {
        var question: String
        var correct: String
        var incorrect: [String]
    }

    var multipleChoice: MultipleChoice?
}

struct LessonState: Equatable, Codable {
    var lessons = [String: Lesson]()
}

class LessonStore: DataStore<LessonState> {
    static let shared = LessonStore(persistenceKey: "lessons1", defaultModel: .init())
}

extension LessonStore {
    func modifyUnit(lessonId: String, unitIndex: Int, block: @escaping (inout Unit) -> Void) {
        modify { state in
            guard var lesson = state.lessons[lessonId], lesson.units.count > unitIndex else { return }
            var unit = lesson.units[unitIndex]
            block(&unit)
            lesson.units[unitIndex] = unit
            state.lessons[lessonId] = lesson
        }
    }
}

extension LessonState {
    func unit(forId id: UnitID) -> Unit? {
        lessons[id.lessonId]?.units.get(id.unitIndex)
    }
}
