import SwiftUI
import UIKit

struct BridgedTextView: UIViewRepresentable {
    struct Options {
//        var placeholder: String = ""

        // Changing these IDs focuses or unfocuses the view
        var focusId: Int = 0
        var unfocusId: Int = 0

        var onFocusChanged: (Bool) -> Void = { _ in }
        var autocapitalization: UITextAutocapitalizationType = .none
        var autocorrection: UITextAutocorrectionType = .no
        var spellChecking: UITextSpellCheckingType = .no
        var keyboardType: UIKeyboardType = .default
        var onReturn: (() -> Void)? = nil
        var alignment: NSTextAlignment = .left
        var selectAllOnFocus: Bool = false
        var xPadding: CGFloat = 0
        var yPadding: CGFloat = 0
    }

    @Binding var text: String
    var options: Options

    func makeUIView(context: Context) -> _BridgedTextView {
        let view = _BridgedTextView()
        view.onTextChange = { text = $0 }
        view.options = options
        view.font = UIFont.funBody
        return view
    }

    func updateUIView(_ uiView: _BridgedTextView, context: Context) {
        uiView.text = text
        uiView.options = options
    }
}

class _BridgedTextView: UITextView, UITextViewDelegate {
    var onTextChange: (String) -> Void = { _ in }

    var options: BridgedTextView.Options = .init() {
        didSet {
//            self.
//            self.placeholder = options.placeholder

            textContainerInset = UIEdgeInsets(top: options.yPadding, left: options.xPadding, bottom: options.yPadding, right: options.xPadding)

            // Update keyboard options
            self.autocapitalizationType = options.autocapitalization
            self.autocorrectionType = options.autocorrection
            self.spellCheckingType = options.spellChecking
            self.keyboardType = options.keyboardType

            self.textAlignment = options.alignment

            // Update focus
            if options.focusId != oldValue.focusId {
                DispatchQueue.main.async {
                    _ = self.becomeFirstResponder()
                }
            } else if options.unfocusId != oldValue.unfocusId {
                DispatchQueue.main.async {
                    _ = self.resignFirstResponder()
                }
            }
        }
    }

    init() {
        super.init(frame: .zero, textContainer: nil)
        self.delegate = self
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            options.onFocusChanged(true)
            if options.selectAllOnFocus {
                DispatchQueue.main.async {
                    self.selectAll(nil)
                }
            }
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            options.onFocusChanged(false)
        }
        return result
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        onTextChange(textView.text)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let onReturn = options.onReturn, text == "\n" { // Return key
            onReturn()
            return false
        }
        return true
    }
}
