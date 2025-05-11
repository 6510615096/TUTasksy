//
//  ChatsTabView.swift
//  TUTasksy
//
//  Created by Ponthipa Teerapravet on 5/5/2568 BE.
//

import SwiftUI
import FirebaseAuth

struct ChatsTabView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var conversations: [Conversation] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if conversations.isEmpty {
                    Text("No conversations yet")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                } else {
                    List(conversations) { conversation in
                        NavigationLink(destination: ChatsRoomView(conversationId: conversation.id ?? ""),
                            label: {
                            Text("Chat ID: \(conversation.id ?? "Unknown")")
                                .padding()
                            }
                        )
                    }
                }
            }
            .onAppear {
                //validateAuth()
                fetchConversations()
            }
        }
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            print("Not logged in")
        }
    }
    
    private func fetchConversations() {
        self.conversations = [
            Conversation(id: "1", participantIds: ["user1", "user2"], lastMessage: "Hello", updatedAt: Date()),
            Conversation(id: "2", participantIds: ["user1", "user3"], lastMessage: "Hi", updatedAt: Date())
        ]
    }
}

#Preview {
    ChatsTabView()
}
