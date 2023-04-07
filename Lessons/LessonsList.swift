import SwiftUI

struct LessonsList: View {
    @State private var lessons = [Lesson]()
    @State private var showingNewLessonDialog = false
    @State private var showingSettings = false

    var body: some View {
        FunScreen {
            header
            list
                .onReceive(LessonStore.shared.publisher.map({ lessonState in
                    return lessonState.lessons.values.sorted(by: { $0.date > $1.date })
                }).removeDuplicates(), perform: { self.lessons = $0 })
        }
        .sheet(isPresented: $showingNewLessonDialog) {
            NewLesson { lesson in
                showingNewLessonDialog = false
                guard let lesson else { return }
                // Append the lesson
                LessonStore.shared.model.lessons[lesson.id] = lesson
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                Settings()
            }
        }
    }

    @ViewBuilder private var header: some View {
        FunHeader(
            title: "Courses",
            leadingButton: {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
            },
            trailingButton: {
                Button("Add") {
                    if UserDefaults.standard.string(forKey: "apiKey")?.nilIfEmpty == nil {
                        showingSettings = true
                    } else {
                        showingNewLessonDialog = true
                    }
                }
            })
    }

    @ViewBuilder private var list: some View {
        List {
            ForEach(lessons) { lesson in
                NavigationLink(destination: { LessonView(id: lesson.id) }) {
                    Text(lesson.title)
                }
                .asFunListCell
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let lesson = lessons[index]
                    LessonStore.shared.model.lessons[lesson.id] = nil
                }
            }
        }
        .asFunList
    }
}
