import SwiftUI

struct UnitView: View {
    var lessonId: String
    var unitIndex: Int

    var body: some View {
        WithSnapshot(dataStore: LessonStore.shared, snapshot: { $0.unitViewSnapshot(lessonId: lessonId, unitIndex: unitIndex) }) { snapshot in
            if let snapshot {
                _UnitView(lesson: snapshot.lesson, unit: snapshot.unit, unitIndex: unitIndex)
            }
        }
    }
}

private struct UnitViewSnapshot: Equatable {
    var lesson: Lesson
    var unit: Unit
}

private extension LessonState {
    func unitViewSnapshot(lessonId: String, unitIndex: Int) -> UnitViewSnapshot? {
        guard let lesson = lessons[lessonId] else { return nil }
        guard let unit = lesson.units.get(unitIndex) else { return nil }
        return UnitViewSnapshot(lesson: lesson, unit: unit)
    }
}

private struct _UnitView: View {
    var lesson: Lesson
    var unit: Unit
    var unitIndex: Int

    @State private var mode = UnitViewMode.info
    @State private var generationInProgress = false

    var body: some View {
        FunScreen {
            FunHeader(title: unit.name, leadingButton: { BackButton() }, trailingButton: { EmptyView() })
            modeView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            modePicker
        }
        .task {
            generationInProgress = true
            // TODO: Handle error
            try? await LessonStore.shared.generateUnitContentIfNeeded(lesson: lesson, unitIndex: unitIndex)
            generationInProgress = false
        }
    }

    @ViewBuilder private var modePicker: some View {
        Picker("", selection: $mode) {
            ForEach(UnitViewMode.allCases, id: \.self) {
                Text($0.title)
                    .font(.funBody)
            }
        }
        .blendMode(.luminosity)
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.3), ignoresSafeAreaEdges: .all)
        .disabled(generationInProgress)
        .opacity(generationInProgress ? 0.5 : 1)
    }

    @ViewBuilder private var modeView: some View {
        switch mode {
        case .info:
            InfoView(generationInProgress: generationInProgress, slides: unit.slides ?? [])
        case .review:
            ReviewView()
        case .quiz:
            QuizView(lesson: lesson, unit: unit, unitIndex: unitIndex)
        }
    }
}

private enum UnitViewMode: String, CaseIterable, Identifiable {
    case info
    case review
    case quiz

    var id: UnitViewMode { self }
    var title: String {
        switch self {
        case .info:
            return "Learn"
        case .review:
            return "Practice"
        case .quiz:
            return "Quiz"
        }
    }
}

struct ReviewView: View {
    var body: some View {
        Text("WIP")
    }
}
