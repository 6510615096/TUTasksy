//
//  Conversation.swift
//  TUTasksy
//
//  Created by chanchompash on 10/5/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    let participantIds: [String]
    let lastMessage: String?
    let updatedAt: Date
}
