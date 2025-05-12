import Foundation

struct Message: Identifiable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
}

extension Message: Comparable {
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
}


