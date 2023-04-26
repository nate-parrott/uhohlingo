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
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(unit.slideGroups.flatMap(\.slides)) { slide in
                        SlidePreview(slide: slide)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if generationInProgress {
                    LoaderFeather()
                }
            }
        }
        .task {
            if generationInProgress { return }
            generationInProgress = true
            // TODO: Handle error
            try? await CourseStore.shared.generateSlidesIfNeeded(unitID: unit.id)
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

private struct SlidePreview: View {
    var slide: Slide

    var body: some View {
        Group {
            switch slide.content {
            case .info(let info): Text(info.markdown).lineLimit(nil)
            case .question(let q): Text("Question: \(q.multipleChoice?.question ?? "?")")
            case .title(let c): Text(c.title).font(.funHeader)
            }
        }
        .multilineTextAlignment(.leading)
    }
}
