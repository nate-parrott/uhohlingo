import Foundation

extension String {
    var nilIfEmpty: String? {
        self == "" ? nil : self
    }

    func truncateTail(maxLen: Int) -> String {
        if count + 3 > maxLen {
            if maxLen <= 3 {
                return ""
            }
            return prefix(maxLen - 3) + "..."
        }
        return self
    }

    func truncateTail(maxTokens: Int) -> String {
        truncateTail(maxLen: maxTokens * 3)
    }

    func without(prefix: String) -> String {
        if hasPrefix(prefix) {
            return String(dropFirst(prefix.count))
        }
        return self
    }

    func without(suffix: String) -> String {
        if hasSuffix(suffix) {
            return String(dropLast(suffix.count))
        }
        return self
    }

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var extractCodeFromMessage: String? {
        let parts = components(separatedBy: "```")
        guard parts.count >= 2 else { return nil }
        let code = parts[1]
        return code.without(prefix: "json")
    }
}
