import SwiftUI

struct LessonView: View {
    var id: String

    var body: some View {
        WithSnapshot(dataStore: LessonStore.shared, snapshot: { $0.lessons[id] }) { lesson in
            if let lesson {
                _LessonView(lesson: lesson)
            }
        }
    }
}

private struct _LessonView: View {
    var lesson: Lesson
    @State private var generationError: Error?
    @State private var generationInProgress = false

    var body: some View {
        FunScreen {
            FunHeader(title: lesson.title, leadingButton: {
                BackButton()
            }, trailingButton: {
                EmptyView()
            })
            list
        }
        .task {
            if lesson.units.count == 0 {
                await generateLesson()
            }
        }
    }

    @ViewBuilder private var list: some View {
        List {
            Group {
                ForEach(lesson.units.enumeratedIdentifiable()) { pair in
                    UnitCell(lesson: lesson, unit: pair.value, index: pair.index)
                }
                if generationInProgress {
                    FunProgressView()
                }
                if generationError != nil {
                    Text("Error")
                }
            }
            .asFunListCell
        }
        .asFunList
        .onChange(of: lesson.units.count) { _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    private func generateLesson() async {
        generationInProgress = true
        do {
            try await LessonStore.shared.generateUnits(forLessonWithId: lesson.id)
        } catch {
            print(error)

            generationError = error
        }
        generationInProgress = false
    }
}

private struct UnitCell: View {
    var lesson: Lesson
    var unit: Unit
    var index: Int

    var body: some View {
        NavigationLink(destination: destination) {
            label
        }
    }

    @ViewBuilder private var label: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(unit.name)
            Text(unit.description)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .opacity(0.5)
        }
    }

    @ViewBuilder private var destination: some View {
        UnitView(lessonId: lesson.id, unitIndex: index)
    }
}
