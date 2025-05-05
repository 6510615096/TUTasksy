import SwiftUI
import Firebase

struct TaskCard: Identifiable {
    let id: String
    let title: String
    let description: String
    let reward: String
    let date: Date
    let username: String
    let imageUrl: String?
    let status: String
    let nickname: String
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskCard] = []

    init() {
        fetchTasks()
    }

    func fetchTasks() {
        Firestore.firestore().collection("tasks")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.tasks = documents.compactMap { doc in
                    let data = doc.data()
                    return TaskCard(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        reward: data["reward"] as? String ?? "",
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        username: data["username"] as? String ?? "",
                        imageUrl: data["imageUrl"] as? String,
                        status: data["status"] as? String ?? "Available",
                        nickname: "not set yet"
                    )
                }
            }
    }
}
