import SwiftUI

struct ChatView: View {
    var unitId: UnitID

    @State private var messages: [ChatMessage] = []
    @State private var typing = false

    @State private var text = ""
    @State private var messageCountToShow = 10

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollReader in
                scrollView
                .animation(.niceDefault, value: messages.count)
                .onAppearOrChange(of: scrollToId) { id in
                    if let id {
                        withAnimation {
                            scrollReader.scrollTo(id, anchor: .bottom)
                        }
                    }
    //                    scroller.scrollTo(", anchor: .bottom)
                }
            }
            InputField(text: $text) {
                let text = self.text
                self.text = ""
                if text == "" { return }
                
                Task {
                    try? await ChatStore.shared.send(message: .userSaid(text), toThreadForUnit: unitId)
                }
            }
            .padding()
        }
        .onReceive(ChatStore.shared.publisher.map { $0.threads[unitId]?.messages ?? [] }, perform: { self.messages = $0 })
        .onReceive(ChatStore.shared.publisher.map { $0.threads[unitId]?.typing ?? false }, perform: { self.typing = $0 })
    }

    private var scrollToId: AnyHashable? {
        if typing {
            return "typing"
        }
        return messages.enumeratedIdentifiable().last?.id
    }

    @ViewBuilder private var scrollView: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                TruncatedForEach(items: messages.enumeratedIdentifiable(), itemsToShow: messageCountToShow, showMoreButton: {
                    LoadMoreButton {
                        messageCountToShow += 5
                    }
                }, itemView: { item in
                    MessageView(message: item.value)
                        .id(item.id)
                })
                if typing {
                    TypingView().id("typing")
                }
            }
            .padding(14)
        }
        .overlay {
            if messages.count == 0 && !typing {
                ChatEmptyState()
            }
        }
    }
}

private struct ChatEmptyState: View {
    var body: some View {
        Text("Got a question? Ask the bot...")
            .font(.funBody)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .opacity(0.3)
            .padding(40)
    }
}

struct TruncatedForEach<Item: Identifiable, ShowMore: View, ItemView: View>: View {
    var items: [Item]
    var itemsToShow: Int
    @ViewBuilder var showMoreButton: () -> ShowMore
    @ViewBuilder var itemView: (Item) -> ItemView

    var body: some View {
        if items.count > itemsToShow {
            showMoreButton()
        }
        ForEach(truncatedItems) { item in
            itemView(item)
        }
    }

    private var truncatedItems: [Item] {
        Array(items.suffix(itemsToShow))
    }
}

private struct MessageView: View {
    var message: ChatMessage

    var body: some View {
        switch message {
        case .assistantSaid(let text):
            MessageBubble(isMe: false) {
                Text(text)
            }
            .transition(.scale(scale: 0.1, anchor: .init(x: 0, y: 0.5)))
        case .userSaid(let text):
            SelfMessage(text: text)
        case .userWantsToPractice:
            SelfMessage(text: "Give me some practice questions")
        case .userWantsExplanation:
            SelfMessage(text: "Explain that question to me")
        }
    }
}

private struct SelfMessage: View {
    var text: String

    var body: some View {
        MessageBubble(isMe: true) {
            Text(text)
        }
        .transition(.scale(scale: 0.1, anchor: .init(x: 1, y: 0.5)))
    }
}

extension View {
    var asStandardMessageText: some View {
        self
            .textSelection(.enabled)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .lineLimit(nil)
    }
}

private struct StatusMessage<C: View>: View {
    @ViewBuilder var content: () -> C

    var body: some View {
        content()
            .font(.funBody)
            .opacity(0.5)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .font(.body)
    }
}

private struct MessageBubble<C: View>: View {
    var isMe: Bool
    @ViewBuilder var content: () -> C

    var body: some View {
        content()
            .asStandardMessageText
            .multilineTextAlignment(isMe ? .trailing : .leading)
            .foregroundColor(isMe ? Color.white : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isMe ? Color.accentColor : Color.gray.opacity(0.3))
            }
            .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
            .padding([isMe ? .leading : .trailing], 50)
    }
}

private struct LoadMoreButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Load older messages")
                .foregroundColor(.accentColor)
                .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct InputField: View {
    @Binding var text: String
    var send: () -> Void

    var body: some View {
        HStack {
            TextField("Message...", text: $text, prompt: Text("Message..."))
                .textFieldStyle(.plain)
                .font(.funBody)

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 30))
            }
            .buttonStyle(.plain)
        }
        .onSubmit(of: .text) {
            send()
        }
        .padding(8)
        .padding(.leading)
        .background {
            InputFieldBackdrop()
        }
    }
}

private struct InputFieldBackdrop: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10)
        let darkColor = Color(white: 0.5)

        ZStack {
            shape.fill(Color.black)
                .offset(y: 3)
                .opacity(0.2)

            shape
                .fill(Color.white)

//            shape.strokeBorder(Color.black, lineWidth: 1.5)
//                .opacity(0.3)
        }
    }
}

//
//struct ChatView<Model: ChatMessageModel, MessageBody: View>: View {
//    var messages: [Model]
//    @ViewBuilder var messageBody: (Model) -> MessageBody
//    @State private var olderMessagePages = 0
//
//    var body: some View {
//        VStack {
//            ScrollViewReader { scroller in
//                GeometryReader { geo in
//                    ScrollView(.vertical) {
//                        LazyVStack(spacing: 14) {
//                            if messages.count > recentMessages.count {
//                                LoadMoreButton {
//                                    olderMessagePages += 1
//                                }
//                            }
//                            ForEach(recentMessages) { message in
//                                MessageView(isMe: message.isMe, isSystem: message.isSystem) {
//                                    messageBody(message)
//                                }
//                                .transition(.scale(scale: 0.1, anchor: .init(x: message.isMe ? 1 : 0, y: 0.5)))
//                                .id(message.id)
//                            }
//                        }
//                        .padding(14)
////                        .frame(minHeight: geo.size.height, alignment: .bottom)
//                        .id("bottom")
//                    }
//                }
//                .animation(.niceDefault, value: messages.last?.id)
//                .onAppearOrChange(messages.last(where: \.shouldScrollToMessage)) { lastScrollable in
//                    if let lastScrollable {
//                        withAnimation {
//                            scroller.scrollTo(lastScrollable.id, anchor: .bottom)
//                        }
//                    }
////                    scroller.scrollTo(", anchor: .bottom)
//                }
//            }
//        }
//    }
//
//    private var recentMessages: [Model] {
//        Array(messages.suffix(20 + (olderMessagePages + 5)))
//    }
//}
//
//private struct LoadMoreButton: View {
//    var action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            Text("Load older messages")
//                .foregroundColor(.accentColor)
//                .padding()
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
//private struct MessageView<C: View>: View {
//    var isMe: Bool
//    var isSystem: Bool
//    @ViewBuilder var content: () -> C
//
//    var body: some View {
//        content()
//            .foregroundColor(isMe || isSystem ? Color("Background") : Color("Foreground"))
//            .background {
//                RoundedRectangle(cornerRadius: 20, style: .continuous)
//                    .fill(isMe ? Color.accentColor : (isSystem ? Color("Foreground") : Color.gray.opacity(0.3)))
//            }
//            .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
//            .padding([isMe ? .leading : .trailing], 50)
//    }
//}
