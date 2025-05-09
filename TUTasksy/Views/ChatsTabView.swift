//
//  ChatsTabView.swift
//  TUTasksy
//
//  Created by Ponthipa Teerapravet on 5/5/2568 BE.
//

import SwiftUI
import FirebaseAuth

struct ChatsTabView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.messages) { msg in
                        HStack {
                            if msg.senderId == Auth.auth().currentUser?.uid {
                                Spacer()
                                Text(msg.text)
                                    .padding()
                                    .background(Color.green.opacity(0.3))
                                    .cornerRadius(10)
                            } else {
                                Text(msg.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .id(msg.id)
                    }
                }
                .onChange(of: viewModel.messages.count) { oldValue, newValue in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    viewModel.sendMessage(text: messageText)
                    messageText = ""
                }
            }
            .padding()
        }
    }
}
