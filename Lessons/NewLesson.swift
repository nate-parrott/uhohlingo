import SwiftUI

struct NewLesson: View {
    var onDone: (Lesson?) -> Void

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
                    onDone(Lesson(id: UUID().uuidString, date: Date(), title: title, prompt: prompt, units: []))
                }
            )
        }
    }
}
