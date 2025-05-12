import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct TaskCardView: View {
    let task: TaskCard
    @State private var isPressed = false
    @State private var showCommentPanel = false
    @State private var taskImage: UIImage? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isLoadingTaskImage = false
    @State private var isLoadingProfileImage = false
    @State private var showProfile = false
    @State private var isLiked: Bool = false
    @State private var likeCount: Int = 0
    @State private var isUpdatingLike = false


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Button(action: { showProfile = true }) {
                    ZStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else if isLoadingProfileImage {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .overlay(ProgressView())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .overlay(Text(task.username.prefix(1)).font(.headline).foregroundColor(.white))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showProfile) {
                    if let currentUser = Auth.auth().currentUser, currentUser.uid == task.userId {
                        ProfileTabView()
                    } else {
                        NavigationView {
                            UserProfileView(userId: task.userId)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(task.username)
                        .font(.headline)
                        .foregroundColor(.brown)

                    Text(formatDate(task.date))
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }

                Spacer()

                Text(task.status)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        task.status == "Available" ?
                            Color.green.opacity(0.2) :
                            Color.red.opacity(0.2)
                    )
                    .foregroundColor(task.status == "Available" ? .green : .red)
                    .clipShape(Capsule())
            }

            Text(task.description)
                .font(.body)
                .lineLimit(nil)
                .padding(.top, 4)

            Text("Reward: \(task.reward) baht")
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundColor(.orange)
                .padding(.top, 4)

            Text("Max: \(task.maxAccepted) people | Currently accepted: \(task.acceptedUserIds.count)")
                .font(.caption)
                .foregroundColor(.blue)

            if let imageUrl = task.imageUrl {
                ZStack {
                    if let taskImage = taskImage {
                        Image(uiImage: taskImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                    } else if isLoadingTaskImage {
                        ProgressView()
                            .frame(height: 200)
                    } else {
                        Image(systemName: "photo")
                            .frame(height: 200)
                    }
                }
                .onAppear {
                    loadTaskImage(from: imageUrl)
                }
                .padding(.vertical, 4)
            }

            HStack {
                Button(action: {
                    markInterest()
                }) {
                    Text("I'm interested")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            (task.status == "Assigned" ||
                             task.acceptedUserIds.contains(Auth.auth().currentUser?.uid ?? "") ||
                             task.acceptedUserIds.count >= task.maxAccepted)
                            ? Color.gray
                            : Color.pink.opacity(0.8)
                        )
                        .cornerRadius(20)
                }
                .disabled(
                    task.status == "Assigned" ||
                    task.acceptedUserIds.contains(Auth.auth().currentUser?.uid ?? "") ||
                    task.acceptedUserIds.count >= task.maxAccepted
                )


                Spacer()

                // Like button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                        toggleLike()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(isLiked ? .pink : .pink.opacity(0.5))
                            .scaleEffect(isPressed ? 1.4 : 1.0) // เพิ่ม scale effect
                            .animation(.easeInOut(duration: 0.2), value: isPressed)
                        Text("\(likeCount)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.01)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
                .padding(.horizontal, 8)


                // Comment button
                Button(action: {
                    showCommentPanel = true
                }) {
                    Image(systemName: "bubble.right")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .sheet(isPresented: $showCommentPanel) {
                    CommentView(task: task)
                        .presentationDetents([.fraction(0.7)])
                }
                .padding(.horizontal, 8)

                // Report button
                Button(action: {
                    // Report action
                }) {
                    Image(systemName: "flag")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal, 8)
            }
            if Auth.auth().currentUser?.uid == task.userId {
                if !task.acceptedUserIds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accepted list:")
                            .font(.subheadline)
                            .bold()
                        ForEach(task.acceptedUserIds, id: \.self) { userId in
                            InterestedUserRow(userId: userId)
                        }
                    }
                } else if !task.interestedUserIds.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("List of interested people:")
                            .font(.subheadline)
                            .bold()
                        ForEach(task.interestedUserIds, id: \.self) { userId in
                            InterestedUserRow(
                                userId: userId,
                                onAccept: { assignTask(to: userId) },
                                onReject: { rejectInterest(userId: userId) }
                            )
                        }
                    }
                }
                
            }

        }
        .padding()
        .background(Color(hex: "#FFFAED"))
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .onAppear {
            loadProfileImage(for: task.userId)
            loadInitialLikeStatus()
        }
    }

    private func loadInitialLikeStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLiked = task.likeUserIds.contains(currentUserId)
        likeCount = task.likeUserIds.count
    }

    private func loadTaskImage(from urlString: String) {
        guard !urlString.isEmpty else { return }

        isLoadingTaskImage = true
        let storageRef = Storage.storage().reference(forURL: urlString)

        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            isLoadingTaskImage = false
            if let data = data, let image = UIImage(data: data) {
                self.taskImage = image
            }
        }
    }
    
    private func assignTask(to userId: String) {
        let db = Firestore.firestore()
        let taskRef = db.collection("tasks").document(task.id)
        var newAccepted = task.acceptedUserIds
        if !newAccepted.contains(userId) {
            newAccepted.append(userId)
        }
        let newStatus = (newAccepted.count >= task.maxAccepted) ? "Assigned" : "Available"
        taskRef.updateData([
            "acceptedUserIds": newAccepted,
            "status": newStatus
        ]) { error in
            if error == nil {
                print("Task assigned.")
            }
        }
    }

    private func rejectInterest(userId: String) {
        let db = Firestore.firestore()
        let taskRef = db.collection("tasks").document(task.id)
        taskRef.updateData([
            "interestedUserIds": FieldValue.arrayRemove([userId])
        ]) { error in
            if error == nil {
                print("Rejected user: \(userId)")
            }
        }
    }

    
    private func markInterest() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let taskRef = db.collection("tasks").document(task.id)

        taskRef.updateData([
            "interestedUserIds": FieldValue.arrayUnion([currentUserId])
        ]) { error in
            if error == nil {
                print("Marked as interested.")
            }
        }
    }

    
    private func toggleLike() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard !isUpdatingLike else { return } // ป้องกันกดซ้ำ

        isUpdatingLike = true

        let db = Firestore.firestore()
        let taskRef = db.collection("tasks").document(task.id)

        if isLiked {
            taskRef.updateData([
                "likeUserIds": FieldValue.arrayRemove([currentUserId])
            ]) { error in
                isUpdatingLike = false
                if error == nil {
                    withAnimation {
                        isLiked = false
                        likeCount -= 1
                    }
                }
            }
        } else {
            taskRef.updateData([
                "likeUserIds": FieldValue.arrayUnion([currentUserId])
            ]) { error in
                isUpdatingLike = false
                if error == nil {
                    withAnimation {
                        isLiked = true
                        likeCount += 1
                    }
                }
            }
        }
    }



    private func loadProfileImage(for userId: String) {
        guard !userId.isEmpty else { return }

        isLoadingProfileImage = true
        let db = Firestore.firestore()

        db.collection("profiles").document(userId).getDocument { document, error in
            if let document = document, document.exists,
               let data = document.data(),
               let profileImageUrl = data["profileImageUrl"] as? String {
                
                let storageRef = Storage.storage().reference(forURL: profileImageUrl)
                storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                    isLoadingProfileImage = false
                    if let data = data, let image = UIImage(data: data) {
                        self.profileImage = image
                    }
                }
            } else {
                isLoadingProfileImage = false
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}


/*
 #Preview {
 TaskCardView()
 }
 */
