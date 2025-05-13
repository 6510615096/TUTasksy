import SwiftUI
import FirebaseStorage

struct MessageBubble: View {
    let message: Message
    let currentUserId: String

    @State private var loadedImage: UIImage? = nil
    @State private var isLoadingImage = false
    @State private var showFullImage = false

    var body: some View {
        HStack {
            if message.senderId == currentUserId { Spacer() }
            VStack(alignment: .leading) {
                // แสดงรูปถ้ามี imageUrl
                if let imageUrl = message.imageUrl, !imageUrl.isEmpty {
                    ZStack {
                        if let loadedImage = loadedImage {
                            Image(uiImage: loadedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .cornerRadius(12)
                                .onTapGesture {
                                    showFullImage = true
                                }
                        } else if isLoadingImage {
                            ProgressView()
                                .frame(width: 200, height: 200)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }
                    }
                    .onAppear {
                        loadImageFromFirebaseStorage(urlString: imageUrl)
                    }
                    .sheet(isPresented: $showFullImage) {
                        FullImageView(imageUrl: imageUrl)
                    }
                }
                // แสดงข้อความถ้ามี text
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding()
                        .background(message.senderId == currentUserId ? Color(hex: "#FFFAED") : Color.blue.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(20)
                }
            }
            if message.senderId != currentUserId { Spacer() }
        }
        .padding(.horizontal)
    }

    private func loadImageFromFirebaseStorage(urlString: String) {
        guard !urlString.isEmpty, loadedImage == nil, !isLoadingImage else { return }
        isLoadingImage = true
        let storageRef = Storage.storage().reference(forURL: urlString)
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                self.loadedImage = uiImage
            }
            self.isLoadingImage = false
        }
    }
}
