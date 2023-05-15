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
    @Published var showingChat = false
    @Published var currentSlide: Slide.ID?
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
    @EnvironmentObject private var unitViewState: UnitViewState

    var body: some View {
        FunScreen {
            FunHeader(title: unit.name, leadingButton: { BackButton() }, trailingButton: { chatToggleButton })
            content
        }
        .sheet(isPresented: .init(get: { unitViewState.showingChat }, set: { unitViewState.showingChat = $0 }), content: {
            chat
        })
        .task {
            if generationInProgress { return }
            generationInProgress = true
            // TODO: Handle error
            try? await CourseStore.shared.generateSlidesIfNeeded(unitID: unit.id)
            generationInProgress = false
        }
    }

    @ViewBuilder private var chatToggleButton: some View {
        Button(action: { unitViewState.showingChat = !unitViewState.showingChat }) {
            Image(systemName: "questionmark.bubble.fill")
        }
    }

    @ViewBuilder private var content: some View {
        VStack(spacing: 0) {
            if let curSlide {
                switch curSlide.content {
                case .info(let info): InfoSlide(info: info).id(curSlide.id)
                case .question(let q): QuestionSlide(question: q, unitID: unit.id, wantsToShowChat: { unitViewState.showingChat = true }).id(curSlide.id)
                case .title(let t): TitleSlide(titleSlide: t).id(curSlide.id)
                }
            } else {
                Spacer()
            }
            Divider()
            HStack(spacing: 14) {
                Button(action: { unitViewState.currentSlide = prevSlideId }) {
                    Image(systemName: "arrow.backward")
                }
                .disabled(prevSlideId == nil)
                .frame(width: 56)

                Button(action: { unitViewState.currentSlide = nextSlideId }) {
                    if generationInProgress && nextSlideId == nil {
                        FunProgressView()
                    } else {
                        Text("Next")
                    }
                }
                .disabled(nextSlideId == nil)
            }
            .buttonStyle(FunButtonStyle())
            .padding(Constants.slideMargin)
        }
    }

    @ViewBuilder private var chat: some View {
        let doneButton = Button(action: { unitViewState.showingChat = false }) {
            Image(systemName: "xmark")
        }
        FunScreen {
            FunHeader(title: "Chat", leadingButton: { EmptyView() }, trailingButton: { doneButton })
            ChatView(unitId: unit.id)
        }
    }

    private var curSlide: Slide? {
        if let id = unitViewState.currentSlide, let slide = allSlides.first(where: { $0.id == id }) {
            return slide
        }
        return allSlides.first
    }

    private var allSlides: [Slide] {
        unit.slideGroups.flatMap(\.slides)
    }

    private var prevSlideId: Slide.ID? {
        if let curSlide,
            let curIdx = allSlides.firstIndex(where: { $0.id == curSlide.id }),
            curIdx > 0 {
            return allSlides[curIdx - 1].id
        }
        return nil
    }

    private var nextSlideId: Slide.ID? {
        if let curSlide,
            let curIdx = allSlides.firstIndex(where: { $0.id == curSlide.id }),
            curIdx + 1 < allSlides.count {
            return allSlides[curIdx + 1].id
        }
        return nil
    }
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
