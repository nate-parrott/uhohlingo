import SwiftUI

struct UnitView: View {
    var id: Unit.ID

    @StateObject private var unitViewState = UnitViewState()

    var body: some View {
        WithSnapshot(dataStore: CourseStore.shared, snapshot: { $0.unitViewSnapshot(id: id) }) { snapshot in
            if let snapshot {
                _UnitView(course: snapshot.course, unit: snapshot.unit)
            }
        }
        .environmentObject(unitViewState)
    }
}

class UnitViewState: ObservableObject {
    // TODO
    var showingChat = false
}

private struct UnitViewSnapshot: Equatable {
    var course: Course
    var unit: Unit
}

private extension CourseState {
    func unitViewSnapshot(id: Unit.ID) -> UnitViewSnapshot? {
        guard let course = courses[id.course] else { return nil }
        guard let unit = course.units[id] else { return nil }
        return UnitViewSnapshot(course: course, unit: unit)
    }
}

private struct _UnitView: View {
    var course: Course
    var unit: Unit

    @State private var generationInProgress = false
//    @EnvironmentObject private var unitViewState: UnitViewState

    var body: some View {
        FunScreen {
            FunHeader(title: unit.name, leadingButton: { BackButton() }, trailingButton: { EmptyView() })
            Color.red
        }
        .task {
            generationInProgress = true
            // TODO: Handle error
//            try? await LessonStore.shared.generateUnitContentIfNeeded(lesson: lesson, unitIndex: unitIndex)
            generationInProgress = false
        }
    }

//    @ViewBuilder private var modePicker: some View {
//        Picker("", selection: modeBinding) {
//            ForEach(UnitViewMode.allViewableCases, id: \.self) {
//                Text($0.title)
//                    .font(.funBody)
//            }
//        }
//        .blendMode(.luminosity)
//        .pickerStyle(SegmentedPickerStyle())
//        .padding()
//        .padding(.horizontal, 6)
//        .background(Color.white.opacity(0.3), ignoresSafeAreaEdges: .all)
//        .disabled(generationInProgress)
//        .opacity(generationInProgress ? 0.5 : 1)
//    }

}
