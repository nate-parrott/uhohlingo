import SwiftUI

struct CourseView: View, Equatable {
    var id: Course.ID

    var body: some View {
        WithSnapshot(dataStore: CourseStore.shared, snapshot: { $0.courses[id] }) { course in
            if let course {
                _CourseView(course: course)
            }
        }
    }
}

private struct _CourseView: View {
    var course: Course
    @State private var generationError: Error?
    @State private var generationInProgress = false

    var body: some View {
        FunScreen {
            FunHeader(title: course.title, leadingButton: {
                BackButton()
            }, trailingButton: {
                EmptyView()
            })
            list
        }
        .navigationDestination(for: Unit.ID.self) { unit in
            UnitView(id: unit)
        }
        .task {
            Task.detached { // do not tie to lifecycle of the view
                if course.units.count == 0 {
                    await generateCourse()
                }
            }
        }
    }

    @ViewBuilder private var list: some View {
        List {
            Group {
                ForEach(course.sortedUnits) { unit in
                    UnitCell(unit: unit)
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
        .onChange(of: course.units.count) { _ in
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    private func generateCourse() async {
        generationInProgress = true
        do {
            try await CourseStore.shared.generateUnits(forCourseWithId: course.id)
        } catch {
            print(error)

            generationError = error
        }
        generationInProgress = false
    }
}

private struct UnitCell: View {
    var unit: Unit

    var body: some View {
        NavigationLink(value: unit.id) {
            HStack(spacing: 16) {
                if let emoji = unit.emoji {
                    Text(emoji).font(.system(size: 36))
                }
                label
            }
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
        UnitView(id: unit.id)
    }
}

extension Unit {
    var description: String {
        let parts = topics.prefix(3)
        return parts.joined(separator: ", ") + "…"
    }
}

extension Course {
    var sortedUnits: [Unit] {
        units.values.sorted(by: { $0.index < $1.index })
    }
}
