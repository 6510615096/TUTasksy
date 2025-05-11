//
//  ChatViewModel.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 9/5/2568 BE.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFirestoreCombineSwift

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func loadMessages(for conversationId: String) {
        listener?.remove()
        
        listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
            }
    }

    func sendMessage(to conversationId: String, text: String) {
        guard let user = Auth.auth().currentUser else { return }

        let newMessage = Message(
            senderId: user.uid,
            senderName: user.displayName ?? "Unknown",
            text: text,
            timestamp: Date()
        )

        do {
            _ = try db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(from: newMessage)
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }

    deinit {
        listener?.remove()
    }
}
