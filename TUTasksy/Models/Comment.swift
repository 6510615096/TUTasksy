import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var text: String
    var timestamp: Date
    var userId: String
}
