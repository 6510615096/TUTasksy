import Foundation
import FirebaseFirestore
import SwiftUI

struct ChatPreview: Identifiable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let otherUserProfileImageUrl: String?
    let lastMessage: String
    let lastMessageTime: Date
}

class ChatListViewModel: ObservableObject {
    @Published var chats: [ChatPreview] = []
    private var db = Firestore.firestore()
    
    // ดึงข้อมูลของ user ที่คุยด้วยมาแสดงเป็น chat list ของแต่ละ user
    func fetchChats(for userId: String) {
        db.collection("chats")
            .whereField("users", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                var previews: [ChatPreview] = []
                let group = DispatchGroup()

                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    let users = data["users"] as? [String] ?? []
                    let otherUserId = users.first(where: { $0 != userId }) ?? ""
                    let lastMessage = data["lastMessage"] as? String ?? ""
                    let timestamp = (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date()

                    guard !otherUserId.isEmpty else { continue }

                    group.enter()
                    self?.db.collection("profiles").document(otherUserId).getDocument { profileDoc, _ in
                        let profileData = profileDoc?.data()
                        let nickname = profileData?["nickname"] as? String ?? otherUserId
                        let profileImageUrl = profileData?["profileImageUrl"] as? String
                        let preview = ChatPreview(
                            id: id,
                            otherUserId: otherUserId,
                            otherUserName: nickname,
                            otherUserProfileImageUrl: profileImageUrl,
                            lastMessage: lastMessage,
                            lastMessageTime: timestamp
                        )
                        previews.append(preview)
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    self?.chats = previews.sorted { $0.lastMessageTime > $1.lastMessageTime }
                }
            }
    }
}
