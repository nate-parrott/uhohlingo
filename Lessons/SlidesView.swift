import SwiftUI
import Ink

//struct InfoView: View {
//    var generationInProgress: Bool
//    var slides: [LessonSlide]
//
//    @StateObject private var wc = WebContent(transparent: true)
//    @State private var selectedPage: Int = 0
//
//    var body: some View {
//        WebView(content: wc)
//            .overlay(alignment: .bottom) {
//                if generationInProgress {
//                    LoaderFeather()
//                }
//            }
//            .onAppear {
//                Task.detached {
//                    let html = await htmlFromSlides(slides, bodyOnly: false)
//                    DispatchQueue.main.async { wc.load(html: html, baseURL: nil) }
//                }
//            }
//            .onChange(of: slides, perform: { slides in
//                Task {
//                    let html = await htmlFromSlides(slides, bodyOnly: true)
//                    _ = try? await wc.webview.runAsync(js: "document.body.innerHTML = \(html.encodedAsJSONString)")
//                }
//            })
//    }
//}

private struct LoaderFeather: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.yellow.opacity(0), Color.yellow], startPoint: .top, endPoint: .init(x: 0.5, y: 0.7))
                .edgesIgnoringSafeArea(.all)
            FunProgressView()
                .padding()
                .offset(y: 50)
        }
        .frame(height: 150)
        .allowsHitTesting(false)
    }
}

//private func htmlFromSlides(_ slides: [LessonSlide], bodyOnly: Bool) async -> String {
//    var body = ""
//    let parser = Ink.MarkdownParser()
//    for slide in slides {
//        body += parser.html(from: slide.markdownWithoutImageSearch)
//        body += "<hr>"
//    }
//    if !bodyOnly {
//        return """
//<!DOCTYPE html>
//<head>
//<meta charset="utf-8">
//<meta name="viewport" content="width=device-width, initial-scale=1">
//<style>
//body {
//    font-family: ui-rounded;
//    font-size: 1.2em;
//    line-height: 1.5;
//    padding: 1em;
//}
//hr:last-child { display: none; }
//hr {
//    margin-top: 1.5em;
//    margin-bottom: 1em;
//    border: 1px solid black;
//}
//</style>
//</head>
//<body>
//""" + body + "</body>"
//    } else {
//        return body
//    }
//}
//
//extension LessonSlide {
//    var markdownWithoutImageSearch: String {
//        // Search for strings on their own lines like (IMAGE SEARCH: query) and remove them
//        markdown.replacingOccurrences(of: "\\(IMAGE SEARCH: [a-zA-Z0-9 ]+\\)", with: "", options: .regularExpression, range: nil)
//    }
//}
