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
    static let shared = OpenAIAPI(apiKey: UserDefaults.standard.string(forKey: "apiKey") ?? "", orgId: UserDefaults.standard.string(forKey: "orgId")?.nilIfEmpty)
}

