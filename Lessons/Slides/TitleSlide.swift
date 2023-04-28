import SwiftUI

struct TitleSlide: View {
    var titleSlide: TitleSlideContent

    var body: some View {
        Text(titleSlide.title)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .font(.funHeader)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Constants.slideMargin)
    }
}
