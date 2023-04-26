import Foundation

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

    var slideGroups: IdentifiedArray<SlideGroup>

    struct UnitID: Hashable, Codable {
        var course: Course.ID
        var unit: String
    }
}

struct SlideGroup: Equatable, Codable, Identifiable {
    var slides: IdentifiedArray<Slide>
    var id: SlideGroupID // not globally unique.
    var completedGenerating: Bool

    enum SlideGroupID: Hashable, Codable {
        case topic(String)
    }
}

struct Slide: Equatable, Codable, Identifiable {
    var id: SlideID
    var content: Content

    enum Content: Equatable, Codable {
        case title(TitleSlideContent)
        case info(InfoSlideContent)
        case question(Question)
    }

    struct SlideID: Hashable, Codable {
        var unit: Unit.ID
        var group: SlideGroup.ID
        var slide: String
    }
}

struct TitleSlideContent: Equatable, Codable {
    var title: String
}

struct InfoSlideContent: Equatable, Codable {
    var markdown: String
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

extension CourseStore {
    func modifyUnit(unitID: Unit.ID, block: @escaping (inout Unit) -> Void) {
        modify { state in
            guard var course = state.courses[unitID.course], var unit = course.units[unitID] else { return }
            block(&unit)
            course.units[unit.id] = unit
            state.courses[unitID.course] = course
        }
    }
}
//
//extension LessonState {
//    func unit(forId id: UnitID) -> Unit? {
//        lessons[id.lessonId]?.units.get(id.unitIndex)
//    }
//}
