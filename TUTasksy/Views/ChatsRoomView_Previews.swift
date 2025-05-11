//
//  ChatsRoomView_Previews.swift
//  TUTasksy
//
//  Created by chanchompash on 11/5/2568 BE.
//

import SwiftUI

struct ChatsRoomView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsRoomView(conversationId: "preview-id")
            .environmentObject(ChatViewModelMock())
    }
}
