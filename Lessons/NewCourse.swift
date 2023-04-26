import SwiftUI

struct NewCourse: View {
    var onDone: (Course?) -> Void

    @State private var title = ""
    @State private var prompt = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                }
                Section(header: Text("Extra Instructions")) {
                    TextField("Prompt", text: $prompt)
                }
            }
            .navigationBarTitle("New Lesson")
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDone(nil)
                },
                trailing: Button("Done") {
                    onDone(.init(id: .assign(), date: Date(), title: title, extraInstructions: prompt, units: [:]))
                }
            )
        }
    }
}
