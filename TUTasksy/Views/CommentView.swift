//
//  CommentView.swift
//  TUTasksy
//
//  Created by Ponthipa Teerapravet on 7/5/2568 BE.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommentView: View {
    let task: TaskCard
    @State private var userNickname = ""
    @State private var newComment = ""
    @State private var comments: [Comment] = []

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Comments")
                        .font(.headline)
                        .frame(maxWidth: .infinity ,alignment: .center)
                    if comments.isEmpty {
                        Spacer(minLength: 150)
                        Text("No comments yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity ,alignment: .center)
                    }
                    ForEach(comments) { comment in
                        HStack(alignment: .top) {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Text(String(comment.username.prefix(1)))
                                        .foregroundColor(.white)
                                        .bold()
                                )
                            
                            VStack(alignment: .leading) {
                                Text(comment.username)
                                    .bold()
                                Text(comment.text)
                                Text(timeAgo(comment.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                }
                .padding()
            }

            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 35, height: 35)
                    .overlay(
                        Text(String(userNickname.prefix(1)))
                            .foregroundColor(.white)
                            .bold()
                    )
                    
                TextField("Post your reply", text: $newComment)
                    .padding(.horizontal)
                    .frame(height: 44)
                    .background(Color(.systemGray6))
                    .cornerRadius(22)

                Button(action: postComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle("Comment")
        .onAppear(perform: fetchComments)
        .onAppear {
            fetchUserNickname()
        }
    }

    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func fetchComments() {
        let db = Firestore.firestore()
        db.collection("tasks")
            .document(task.id)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self.comments = docs.compactMap { doc in
                    try? doc.data(as: Comment.self)
                }
            }
    }
    
    func fetchUserNickname() {
        guard let user = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let nickname = data["nickname"] as? String else {
                print("Failed to get nickname")
                return
            }
            
            self.userNickname = nickname
        }
    }

    func postComment() {
        guard !newComment.isEmpty else { return }
        let db = Firestore.firestore()
        let comment = Comment(
            id: UUID().uuidString,
            username: userNickname.isEmpty ? "Loading..." : userNickname, // ใช้ชื่อผู้ใช้จริง
            text: newComment,
            timestamp: Date()
        )

        do {
            try db.collection("tasks")
                .document(task.id)
                .collection("comments")
                .document(comment.id ?? "comment")
                .setData(from: comment)
            newComment = ""
        } catch {
            print("Error posting comment: \(error)")
        }
    }
}

/*
#Preview {
    CommentView()
}*/
