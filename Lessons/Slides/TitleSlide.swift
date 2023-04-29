import SwiftUI

struct TitleSlide: View {
    var titleSlide: TitleSlideContent

    var body: some View {
        FunTitleText(text: fullText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Constants.slideMargin)
    }

    private var fullText: String {
        if let emoji = titleSlide.emoji {
            return "\(emoji)\n\n\(titleSlide.title)"
        }
        return titleSlide.title
    }
}

// Previews

struct TitleSlide_Previews: PreviewProvider {
    static var previews: some View {
        FunScreen {
            TitleSlide(titleSlide: TitleSlideContent(title: "The Preamble to the Constitution", emoji: "🇺🇸"))
        }
    }
}
