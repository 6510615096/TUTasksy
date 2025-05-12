import SwiftUI
import FirebaseAuth

struct ChatsTabView: View {
    @StateObject var viewModel = ChatListViewModel()
    let currentUserId: String
    
    // หน้าหลักของ Chats เชื่อมไปที่ ChatListRow อีกที
    var body: some View {
        ZStack {
            Color(.white)
                .ignoresSafeArea()

            NavigationView {
                List(viewModel.chats) { chat in
                    NavigationLink(destination: ChatDetailView(chatId: chat.id, currentUserId: currentUserId)) {
                        ChatListRow(chat: chat)
                    }
                }
                .listRowBackground(Color.clear)
                .scrollContentBackground(.hidden)
                .onAppear {
                    viewModel.fetchChats(for: currentUserId)
                }
            }
        }
    }
}

/*
#Preview {
    ChatsTabView()
}*/
