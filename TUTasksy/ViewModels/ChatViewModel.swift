//
//  ChatViewModel.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 9/5/2568 BE.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        fetchMessages()
    }

    func fetchMessages() {
        listener = db.collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
            }
    }

    func sendMessage(text: String) {
        guard let user = Auth.auth().currentUser else { return }
        let newMessage = Message(
            senderId: user.uid,
            senderName: user.displayName ?? "Unknown",
            text: text,
            timestamp: Date()
        )

        do {
            _ = try db.collection("messages").addDocument(from: newMessage)
        } catch {
            print("Error sending message: \(error)")
        }
    }

    deinit {
        listener?.remove()
    }
}
