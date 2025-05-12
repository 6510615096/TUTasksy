import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct CommentView: View {
    let task: TaskCard
    @State private var userNickname = ""
    @State private var userProfileImage: UIImage? = nil
    @State private var isLoadingUserProfileImage = false
    @State private var newComment = ""
    @State private var comments: [Comment] = []

    var body: some View {
        VStack {
            // ส่วน comments ทั้งหมดของแต่ละ task
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
                        CommentRowView(comment: comment)
                    }
                }
                .padding()
            }
            
            // ส่วนสำหรับพิมพ์ส่ง comment ใหม่
            HStack {
                ZStack {
                    if let image = userProfileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    } else if isLoadingUserProfileImage {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 35, height: 35)
                            .overlay(ProgressView())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 35, height: 35)
                            .overlay(
                                Text(String(userNickname.prefix(1)))
                                    .foregroundColor(.white)
                                    .bold()
                            )
                    }
                }

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
            fetchUserProfileImage()
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
        db.collection("profiles").document(user.uid).getDocument { document, error in
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

    func fetchUserProfileImage() {
        guard let user = Auth.auth().currentUser else { return }
        isLoadingUserProfileImage = true
        let db = Firestore.firestore()
        db.collection("profiles").document(user.uid).getDocument { document, error in
            isLoadingUserProfileImage = false
            guard let document = document, document.exists,
                  let data = document.data(),
                  let profileImageUrl = data["profileImageUrl"] as? String, !profileImageUrl.isEmpty else { return }
            let storageRef = Storage.storage().reference(forURL: profileImageUrl)
            storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                if let data = data, let image = UIImage(data: data) {
                    self.userProfileImage = image
                }
            }
        }
    }

    func postComment() {
        guard !newComment.isEmpty else { return }
        let db = Firestore.firestore()
        let comment = Comment(
            id: UUID().uuidString,
            username: userNickname.isEmpty ? "Loading..." : userNickname,
            text: newComment,
            timestamp: Date(),
            userId: Auth.auth().currentUser?.uid ?? "Loading..."
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

// ส่วนของแต่ละ comment
struct CommentRowView: View {
    let comment: Comment
    @State private var profileImage: UIImage? = nil
    @State private var nickname: String = ""
    @State private var isLoading = false

    var body: some View {
        HStack(alignment: .top) {
            ZStack {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 35, height: 35)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                } else if isLoading {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 35, height: 35)
                        .overlay(ProgressView())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 35, height: 35)
                        .overlay(Text(String(nickname.isEmpty ? comment.username.prefix(1) : nickname.prefix(1)))
                            .foregroundColor(.white)
                            .bold())
                }
            }
            .onAppear { fetchProfile() }

            VStack(alignment: .leading) {
                Text(nickname.isEmpty ? comment.username : nickname)
                    .bold()
                Text(comment.text)
                Text(timeAgo(comment.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }

    private func fetchProfile() {
        guard !comment.userId.isEmpty else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("profiles").document(comment.userId).getDocument { document, error in
            isLoading = false
            guard let document = document, document.exists,
                  let data = document.data() else { return }
            self.nickname = data["nickname"] as? String ?? comment.username
            if let profileImageUrl = data["profileImageUrl"] as? String, !profileImageUrl.isEmpty {
                let storageRef = Storage.storage().reference(forURL: profileImageUrl)
                storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                    if let data = data, let image = UIImage(data: data) {
                        self.profileImage = image
                    }
                }
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/*
#Preview {
    CommentView()
}*/
