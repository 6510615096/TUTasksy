import Foundation
import FirebaseFirestore
import FirebaseAuth

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskCard] = []

    func fetchTasks() {
        let db = Firestore.firestore()

        db.collection("tasks").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No documents")
                return
            }

            self.tasks = documents.compactMap { doc in
                let data = doc.data()
                let id = doc.documentID
                let userId = data["userId"] as? String ?? ""
                let title = data["title"] as? String ?? ""
                let username = data["username"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let timestamp = data["date"] as? Timestamp
                let date = timestamp?.dateValue() ?? Date()
                let reward = data["reward"] as? String ?? ""
                let imageUrl = data["imageUrl"] as? String
                let status = data["status"] as? String ?? "Available"
                let likeUserIds = data["likeUserIds"] as? [String] ?? []
                let interestedUserIds = data["interestedUserIds"] as? [String] ?? []
                let acceptedUserId = data["acceptedUserId"] as? String
                let acceptedUserIds = data["acceptedUserIds"] as? [String] ?? []
                let maxAccepted = data["maxAccepted"] as? Int ?? 1

                return TaskCard(
                    id: id,
                    userId: userId,
                    username: username,
                    title: title,
                    description: description,
                    date: date,
                    reward: reward,
                    imageUrl: imageUrl,
                    status: status,
                    likeUserIds: likeUserIds,
                    interestedUserIds: interestedUserIds,
                    acceptedUserIds: acceptedUserIds,
                    maxAccepted: maxAccepted
                )
            }
        }
    }
}

