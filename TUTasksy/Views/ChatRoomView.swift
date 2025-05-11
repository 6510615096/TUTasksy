import SwiftUI
import FirebaseAuth

struct ChatsRoomView: View {
    let conversationId: String
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.messages) { msg in
                        HStack {
                            if msg.senderId == Auth.auth().currentUser?.uid {
                                Spacer()
                                Text(msg.text)
                                    .padding()
                                    .background(Color.green.opacity(0.3))
                                    .cornerRadius(10)
                            } else {
                                Text(msg.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .id(msg.id)
                    }
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    viewModel.sendMessage(to: conversationId, text: messageText)
                    messageText = ""
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadMessages(for: conversationId)
        }
    }
}

/*struct ChatsRoomView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsRoomView(conversationId: "preview_test_id")
            .environmentObject(ChatViewModelMock())
    }
}

class ChatViewModelMock: ChatViewModel {
    override init() {
        super.init()
        
        // ✅ ข้อความจำลองที่ใช้แสดงใน Preview
        self.messages = [
            Message(
                id: UUID().uuidString,
                senderId: "mock_user_1",
                senderName: "Jen",
                text: "สวัสดีค่ะ!",
                timestamp: Date()
            ),
            Message(
                id: UUID().uuidString,
                senderId: "mock_user_2",
                senderName: "Me",
                text: "หวัดดีครับ เจน",
                timestamp: Date()
            )
        ]
    }

    // ปิดไม่ให้โหลด Firestore จริงใน preview
    override func loadMessages(for conversationId: String) {
        // ไม่ทำอะไรใน mock
    }

    override func sendMessage(to conversationId: String, text: String) {
        // เพิ่มข้อความจำลองเข้า array
        let newMessage = Message(
            id: UUID().uuidString,
            senderId: "mock_user_2",
            senderName: "Me",
            text: text,
            timestamp: Date()
        )
        self.messages.append(newMessage)
    }
}*/
