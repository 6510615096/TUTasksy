//
//  Message.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 9/5/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let senderName: String
    let text: String
    let timestamp: Date
}
