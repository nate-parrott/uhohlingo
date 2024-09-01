import SwiftUI

struct CourseList: View {
    @State private var courses = [Course]()
    @State private var showingNewCourseDialog = false
    @State private var showingSettings = false

    var body: some View {
        FunScreen {
            header
            if courses.count > 0 {
                list
            } else {
                Color.clear
            }
        }
        .onReceive(CourseStore.shared.publisher.map({ state in
            return state.courses.values.sorted(by: { $0.date > $1.date })
        }).removeDuplicates(), perform: { self.courses = $0 })
        .navigationDestination(for: Course.ID.self, destination: { courseID in
            CourseView(id: courseID)
        })
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
                    if (try? ModelChoice.current.llm(json: false)) == nil {
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
                NavigationLink(value: course.id) {
                    Text(course.title)
                }
//                NavigationLink(destination: {
//                    CourseView(id: course.id)
//                }) {
//                    Text(course.title)
//                }
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
