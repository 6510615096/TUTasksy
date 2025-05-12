import SwiftUI

struct ChatDetailView: View {
    @ObservedObject var viewModel = ChatDetailViewModel()
    @State private var newMessage = ""
    
    let chatId: String
    let currentUserId: String

    var body: some View {
        
        // ส่วนของ chats ที่คุยกัน
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, currentUserId: currentUserId)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onReceive(viewModel.$messages) { messages in
                    if let last = messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }


            }
            
            // ส่วนที่พิมพ์ส่งแต่ละ message bubble
            HStack {
                TextField("Message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    guard !newMessage.isEmpty else { return }
                    viewModel.sendMessage(chatId: chatId, senderId: currentUserId, text: newMessage)
                    newMessage = ""
                }
            }
            .padding()
        }
        .onAppear { viewModel.fetchMessages(chatId: chatId) }
        .onDisappear { viewModel.detachListener() }
    }
}

/*
#Preview {
    ChatDetailView()
}
*/
