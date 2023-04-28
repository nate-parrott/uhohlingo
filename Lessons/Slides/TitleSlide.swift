import SwiftUI

struct TitleSlide: View {
    var titleSlide: TitleSlideContent

    var body: some View {
        FunTitleText(text: Text(titleSlide.title))
//        Text(titleSlide.title)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
//            .font(.funHeader)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Constants.slideMargin)
    }
}
