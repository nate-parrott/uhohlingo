import SwiftUI
import ChatToys
//import OpenAIStreamingCompletions

enum ModelChoice: String, Equatable, Codable, CaseIterable {
    case gpt4o
    case gpt4oMini

    func llm(json: Bool, temp: Double = 1.0) throws -> any ChatLLM {
        switch self {
        case .gpt4o:
            return try ChatGPT(credentials: .stored(), options: .init(temp: temp, model: .gpt4_omni, jsonMode: json))
        case .gpt4oMini:
            return try ChatGPT(credentials: .stored(), options: .init(temp: temp, model: .custom("gpt-4o-mini", 128_000), jsonMode: json))
        }
    }

    static var current: ModelChoice {
        if let val = DefaultsKeys.modelChoice.stringVal?.nilIfEmpty, let model = ModelChoice(rawValue: val) {
            return model
        }
        return Self.defaultModel
    }

    static let defaultModel: ModelChoice = .gpt4oMini
}

enum DefaultsKeys: String {
    case openAIKey
    case modelChoice

    var stringVal: String? {
        get {
            UserDefaults.standard.string(forKey: rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: rawValue)
        }
    }
}

enum LLMError: Error {
    case noOpenAIKey
}

extension OpenAICredentials {
    static func stored() throws -> Self {
        if let key = DefaultsKeys.openAIKey.stringVal?.nilIfEmpty {
            return .init(apiKey: key)
        }
        throw LLMError.noOpenAIKey
    }
}

struct Settings: View {
    @AppStorage(DefaultsKeys.openAIKey.rawValue) private var openAIKey: String = ""
    @AppStorage(DefaultsKeys.modelChoice.rawValue) private var model: ModelChoice = .defaultModel

//    @AppStorage("orgId") private var orgId: String = ""
//    @AppStorage("model") private var model: String = defaultModel


    var body: some View {
        Form {
            Section(header: Text("LLM")) {
                Picker("Model", selection: $model) {
                    ForEach(ModelChoice.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                TextField("OpenAI Key", text: $openAIKey)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//private let defaultModel = "gpt-3.5-turbo"
//
//func llmModel() -> String {
//    UserDefaults.standard.string(forKey: "model")?.nilIfEmpty ?? defaultModel
//}
//
////extension OpenAIAPI {
////    static var shared: OpenAIAPI {
////        OpenAIAPI(apiKey: UserDefaults.standard.string(forKey: "apiKey") ?? "", orgId: UserDefaults.standard.string(forKey: "orgId")?.nilIfEmpty)
////    }
////}
