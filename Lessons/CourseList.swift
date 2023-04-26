import SwiftUI

struct CourseList: View {
    @State private var courses = [Course]()
    @State private var showingNewCourseDialog = false
    @State private var showingSettings = false

    var body: some View {
        FunScreen {
            header
            list
                .onReceive(CourseStore.shared.publisher.map({ state in
                    return state.courses.values.sorted(by: { $0.date > $1.date })
                }).removeDuplicates(), perform: { self.courses = $0 })
        }
        .sheet(isPresented: $showingNewCourseDialog) {
            NewCourse { course in
                showingNewCourseDialog = false
                guard let course else { return }
                // Append the lesson
                CourseStore.shared.model.courses[course.id] = course
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
                        showingNewCourseDialog = true
                    }
                }
            })
    }

    @ViewBuilder private var list: some View {
        List {
            ForEach(courses) { course in
                NavigationLink(destination: {
                    CourseView(id: course.id)
                }) {
                    Text(course.title)
                }
                .asFunListCell
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let course = courses[index]
                    CourseStore.shared.model.courses[course.id] = nil
                }
            }
        }
        .asFunList
    }
}
