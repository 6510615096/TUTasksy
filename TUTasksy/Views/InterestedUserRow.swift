import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct InterestedUserRow: View {
    let userId: String
    var onAccept: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil

    @State private var nickname: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var isLoading = false
    @State private var showProfile = false

    var body: some View {
        
        // รายละเอียดของคนที่กดสนใจใน task นั้น
        HStack {
            Button(action: { showProfile = true }) {
                ZStack {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    } else if isLoading {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .overlay(ProgressView())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .overlay(Text(String(nickname.prefix(1))).foregroundColor(.white))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showProfile) {
                NavigationView {
                    UserProfileView(userId: userId)
                }
            }

            VStack(alignment: .leading) {
                Text(userId)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(nickname.isEmpty ? "Loading..." : nickname)
                    .font(.body)
            }
            Spacer()
            if let onAccept = onAccept, let onReject = onReject {
                Button(action: onAccept) {
                    Text("Accept")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 4)
                Button(action: onReject) {
                    Text("Reject")
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
        }
        .onAppear(perform: fetchProfile)
    }

    private func fetchProfile() {
        guard !userId.isEmpty else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("profiles").document(userId).getDocument { doc, error in
            isLoading = false
            guard let doc = doc, doc.exists, let data = doc.data() else { return }
            self.nickname = data["nickname"] as? String ?? ""
            if let url = data["profileImageUrl"] as? String, !url.isEmpty {
                let ref = Storage.storage().reference(forURL: url)
                ref.getData(maxSize: 5 * 1024 * 1024) { data, _ in
                    if let data = data, let img = UIImage(data: data) {
                        self.profileImage = img
                    }
                }
            }
        }
    }
}
