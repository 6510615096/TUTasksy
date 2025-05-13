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
    @State private var showReportAlert = false


    @State private var selectedChatId: String? = nil
    @AppStorage("currentUserId") var currentUserId: String = ""
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    Text("User Profile")
                        .font(.title).fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundStyle(.blue)
                        }
                        .padding(.leading)
                        Spacer()
                    }
                }
                Spacer()
                
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
                Spacer()

                Text(nickname)
                    .font(.title)
                    .fontWeight(.bold)

                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Spacer()

                if userId != currentUserId {
                    Button(action: startChat) {
                        Text("Chat")
                            .font(.headline).fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color(hex: "#C77A17"))
                            .background(Color(hex: "#FFE7E4"))
                            .cornerRadius(12)
                    }
                    .padding(.top)
                    NavigationLink(destination: ChatsTabView(currentUserId: currentUserId), isActive: $navigateToChats) {
                        EmptyView()
                    }
                    .hidden()
                    
                    Button(action: {
                        self.showReportAlert = true
                    }) {
                        Text("Report User")
                            .font(.headline).fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.red)
                            .background(Color(hex: "#E7E7E7"))
                            .cornerRadius(12)
                    }
                    
                    .alert(isPresented: $showReportAlert) {
                        Alert(
                            title: Text("Report User"),
                            message: Text("Are you sure you want to report this user?"),
                            primaryButton: .destructive(Text("Report")) {
                                reportUser()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color(hex: "#FFFAED"))
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
    
    private func reportUser() {
        let reportManager = ReportManager()

        let reason = "Inappropriate behavior"
        reportManager.reportUser(reportedUserId: userId, reason: reason) { error in
            if let error = error {
                print("Failed to report user: \(error.localizedDescription)")
            } else {
                print("Report submitted successfully")
            }
        }
    }

}

