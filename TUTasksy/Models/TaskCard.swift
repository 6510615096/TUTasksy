import Foundation

struct TaskCard: Identifiable {
    var id: String
    var userId: String
    var username: String
    var title: String
    var description: String
    var date: Date
    var reward: String
    var imageUrl: String?
    var status: String
    var likeUserIds: [String]
    var interestedUserIds: [String] = []
    var acceptedUserIds: [String] = []
    var maxAccepted: Int = 1
}
