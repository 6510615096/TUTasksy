//
//  Comment.swift
//  TUTasksy
//
//  Created by Ponthipa Teerapravet on 7/5/2568 BE.
//

import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var text: String
    var timestamp: Date
}
