import SwiftUI
import Ink

struct InfoSlide: View {
    var info: InfoSlideContent

    @StateObject private var wc = WebContent(transparent: true)
    @State private var selectedPage: Int = 0

    var body: some View {
        WebView(content: wc)
            .overlay(alignment: .bottom) {
                if info.generationInProgress {
                    LoaderFeather()
                }
            }
            .onAppear {
                Task.detached {
                    let html = await htmlFromInfoSlide(info, bodyOnly: false)
                    DispatchQueue.main.async { wc.load(html: html, baseURL: nil) }
                }
            }
            .onChange(of: info, perform: { info in
                Task {
                    let html = await htmlFromInfoSlide(info, bodyOnly: true)
                    _ = try? await wc.webview.runAsync(js: "document.body.innerHTML = \(html.encodedAsJSONString)")
                }
            })
    }
}

private func htmlFromInfoSlide(_ slide: InfoSlideContent, bodyOnly: Bool) async -> String {
    let parser = Ink.MarkdownParser()
    let body = parser.html(from: slide.markdown)

    if !bodyOnly {
        return """
<!DOCTYPE html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body {
    font-family: ui-rounded;
    font-size: 1.2em;
    line-height: 1.5;
    padding: \(Constants.slideMargin)px;
    margin: 0;
    margin-bottom: 4em;
}
</style>
</head>
<body>
""" + body + "</body>"
    } else {
        return body
    }
}

//extension LessonSlide {
//    var markdownWithoutImageSearch: String {
//        // Search for strings on their own lines like (IMAGE SEARCH: query) and remove them
//        markdown.replacingOccurrences(of: "\\(IMAGE SEARCH: [a-zA-Z0-9 ]+\\)", with: "", options: .regularExpression, range: nil)
//    }
//}
