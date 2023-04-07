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

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
