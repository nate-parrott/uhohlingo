import Foundation

//struct UnitID: Equatable, Codable, Hashable {
//    var lessonId: String
//    var unitIndex: Int
//}

struct Course: Equatable, Codable, Identifiable {
    var id: ID<Course>
    var date: Date
    var title: String
    var extraInstructions: String
    var units: [Unit.ID: Unit]
}

struct Unit: Equatable, Codable, Identifiable {
    var id: UnitID
    var name: String
    var topics: [String]
    var index: Int

    struct UnitID: Hashable, Codable {
        var course: Course.ID
        var unit: String
    }
}

struct Question: Equatable, Codable, Hashable, Identifiable {
    struct MultipleChoice: Equatable, Codable, Hashable {
        var question: String
        var correct: String
        var incorrect: [String]
    }

    var id: ID<Question>
    var multipleChoice: MultipleChoice?
}

struct CourseState: Equatable, Codable {
    var courses = [Course.ID: Course]()
}

class CourseStore: DataStore<CourseState> {
    static let shared = CourseStore(persistenceKey: "courses", defaultModel: .init())
}

//extension CourseStore {
//    func modifyUnit(unitID:, block: @escaping (inout Unit) -> Void) {
//        modify { state in
//            guard var lesson = state.lessons[lessonId], lesson.units.count > unitIndex else { return }
//            var unit = lesson.units[unitIndex]
//            block(&unit)
//            lesson.units[unitIndex] = unit
//            state.lessons[lessonId] = lesson
//        }
//    }
//}
//
//extension LessonState {
//    func unit(forId id: UnitID) -> Unit? {
//        lessons[id.lessonId]?.units.get(id.unitIndex)
//    }
//}
