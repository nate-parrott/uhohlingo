import SwiftUI

struct TitleSlide: View {
    var titleSlide: TitleSlideContent

    var body: some View {
        VStack(spacing: 20) {
            if let emoji = titleSlide.emoji {
                Text(emoji).font(.system(size: 120))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            FunTitleText(text: titleSlide.title, fontAlignment: .leading, verticalAligmment: .top)
            Spacer()
        }
        .padding(Constants.slideMargin)
    }

//    @ViewBuilder private var emoji: some View {
//        if let emoji = titleSlide.emoji {
//            Text(emoji).font(.system(size: 90))
//        }
//    }
}

// Previews

struct TitleSlide_Previews: PreviewProvider {
    static var previews: some View {
        FunScreen {
            TitleSlide(titleSlide: TitleSlideContent(title: "The Preamble to the Constitution", emoji: "🇺🇸"))
        }
    }
}
