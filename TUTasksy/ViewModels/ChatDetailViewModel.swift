import SwiftUI
import FirebaseFirestore

class ChatDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func fetchMessages(chatId: String) {
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let newMessages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    guard
                        let senderId = data["senderId"] as? String,
                        let text = data["text"] as? String
                    else {
                        return nil
                    }
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    return Message(
                        id: doc.documentID,
                        senderId: senderId,
                        text: text,
                        timestamp: timestamp
                    )
                }

                DispatchQueue.main.async {
                    self?.messages = newMessages
                }
            }
    }

    func sendMessage(chatId: String, senderId: String, text: String) {
        let message: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]

        let messagesRef = db.collection("chats").document(chatId).collection("messages")
        
        messagesRef.addDocument(data: message) { error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                return
            }

            self.db.collection("chats").document(chatId).updateData([
                "lastMessage": text,
                "lastMessageTime": FieldValue.serverTimestamp(),
                "lastSenderName": senderId
            ])
        }
    }

    func detachListener() {
        listener?.remove()
        listener = nil
    }
}

