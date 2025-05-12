import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct UserProfileView: View {
    let userId: String

    @State private var profileImage: UIImage? = nil
    @State private var nickname: String = ""
    @State private var bio: String = ""
    @State private var isLoading = true
    @State private var navigateToChats = false


    @State private var selectedChatId: String? = nil
    @AppStorage("currentUserId") var currentUserId: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 120, height: 120)
                        .overlay(
                            isLoading
                                ? AnyView(ProgressView())
                                : AnyView(Text(nickname.prefix(1)).font(.largeTitle).foregroundColor(.white))
                        )
                }

                Text(nickname)
                    .font(.title)
                    .fontWeight(.bold)

                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)

                if userId != currentUserId {
                    Button(action: startChat) {
                        Text("Chat")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                    NavigationLink(destination: ChatsTabView(currentUserId: currentUserId), isActive: $navigateToChats) {
                        EmptyView()
                    }
                    .hidden()

                }

                Spacer()
            }
            .padding()
            .navigationTitle("User Profile")
            .onAppear(perform: fetchProfile)
            .onAppear {
                        if let user = Auth.auth().currentUser {
                            print("Setting currentUserId: \(user.uid)")
                            currentUserId = user.uid
                        } else {
                            print("No user is logged in.")
                        }
                    }
        }
    }

    private func fetchProfile() {
        let db = Firestore.firestore()
        db.collection("profiles").document(userId).getDocument { doc, error in
            isLoading = false
            guard let doc = doc, doc.exists, let data = doc.data() else { return }
            self.nickname = data["nickname"] as? String ?? ""
            self.bio = data["bio"] as? String ?? ""

            if let url = data["profileImageUrl"] as? String, !url.isEmpty {
                let storageRef = Storage.storage().reference(forURL: url)
                storageRef.getData(maxSize: 5 * 1024 * 1024) { data, _ in
                    if let data = data, let img = UIImage(data: data) {
                        self.profileImage = img
                    }
                }
            }
        }
    }

    private func startChat() {

        guard currentUserId != userId, !currentUserId.isEmpty, !userId.isEmpty else {
            print("Error: Invalid user IDs. currentUserId: \(currentUserId), userId: \(userId)")
            return
        }

        let db = Firestore.firestore()
        db.collection("chats")
            .whereField("users", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching chats: \(error.localizedDescription)")
                    return
                }

                // เช็คว่ามี chat ระหว่าง user อยู่แล้วไหม
                if let docs = snapshot?.documents {
                    if let existingChat = docs.first(where: {
                        let users = $0.data()["users"] as? [String] ?? []
                        return users.contains(userId)
                    }) {
                        self.selectedChatId = existingChat.documentID
                        self.navigateToChats = true
                        return
                    }
                }

                // สร้างแชทใหม่ ถ้า user ไม่เคยคุนกันมาก่อน
                let newChatRef = db.collection("chats").document()
                newChatRef.setData([
                    "users": [currentUserId, userId],  // Ensure both user IDs are added to the "users" array
                    "lastMessage": "",
                    "lastMessageTime": FieldValue.serverTimestamp(),
                    "lastSenderName": ""
                ]) { error in
                    if let error = error {
                        print("Error creating new chat: \(error.localizedDescription)")
                        return
                    }
                    self.selectedChatId = newChatRef.documentID
                    self.navigateToChats = true

                }
            }
    }

}

