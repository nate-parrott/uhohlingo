import SwiftUI
import OpenAIStreamingCompletions

struct Settings: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("orgId") private var orgId: String = ""
    @AppStorage("model") private var model: String = defaultModel


    var body: some View {
        Form {
            Section(header: Text("OpenAI")) {
                TextField("API Key", text: $apiKey)
                TextField("Organization ID", text: $orgId)
                TextField("Model", text: $model)
                Picker(selection: $model, label: Text("Model")) {
                    Text("GPT 3.5").tag("gpt-3.5-turbo")
                    Text("GPT 4").tag("gpt-4")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private let defaultModel = "gpt-3.5-turbo"

func llmModel() -> String {
    UserDefaults.standard.string(forKey: "model")?.nilIfEmpty ?? defaultModel
}

extension OpenAIAPI {
    static var shared: OpenAIAPI {
        OpenAIAPI(apiKey: UserDefaults.standard.string(forKey: "apiKey") ?? "", orgId: UserDefaults.standard.string(forKey: "orgId")?.nilIfEmpty)
    }
}
