import SwiftUI
import FirebaseStorage

struct ChatListRow: View {
    let chat: ChatPreview
    @State private var profileImage: UIImage? = nil
    @State private var isLoadingImage = false

    var body: some View {
        
        HStack {
            ZStack {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                } else if isLoadingImage {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(ProgressView())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(Text(String(chat.otherUserName.prefix(1))).bold())
                }
            }
            .onAppear {
                loadProfileImage()
            }

            VStack(alignment: .leading) {
                Text(chat.otherUserName).bold()
                Text(chat.lastMessage).font(.subheadline).foregroundColor(.gray)
            }

            Spacer()
            Text(timeAgo(chat.lastMessageTime)).font(.caption).foregroundColor(.orange)
        }
        .padding(15)
        .background(Color(hex: "#FFFAED"))
    }

    private func loadProfileImage() {
        guard let url = chat.otherUserProfileImageUrl, !url.isEmpty, profileImage == nil else { return }
        isLoadingImage = true
        let ref = Storage.storage().reference(forURL: url)
        ref.getData(maxSize: 5 * 1024 * 1024) { data, error in
            isLoadingImage = false
            if let data = data, let img = UIImage(data: data) {
                self.profileImage = img
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
