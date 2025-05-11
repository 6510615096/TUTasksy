//
//  ChatViewModelMock.swift
//  TUTasksy
//
//  Created by chanchompash on 11/5/2568 BE.
//

import Foundation

class ChatViewModelMock: ChatViewModel {
    override init() {
        super.init()
        self.messages = [
            Message(id: "1", senderId: "user1", senderName: "Jen", text: "สวัสดีค่ะ", timestamp: Date()),
            Message(id: "2", senderId: "user2", senderName: "Me", text: "สวัสดีครับ", timestamp: Date())
        ]
    }

    override func loadMessages(for conversationId: String) {}
    override func sendMessage(to conversationId: String, text: String) {}
}
