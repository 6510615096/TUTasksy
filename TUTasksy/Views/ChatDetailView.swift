import SwiftUI
import FirebaseAuth

struct ChatDetailView: View {
    @ObservedObject var viewModel = ChatDetailViewModel()
    @State private var newMessage = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    
    let chatId: String
    let currentUserId: String

    var body: some View {
        
        // ส่วนของ chats ที่คุยกัน
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, currentUserId: currentUserId)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onReceive(viewModel.$messages) { messages in
                    if let last = messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // ส่วนที่พิมพ์ส่งแต่ละ message bubble
            HStack {
                TextField("Message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    guard !newMessage.isEmpty else { return }
                    viewModel.sendMessage(chatId: chatId, senderId: currentUserId, text: newMessage)
                    newMessage = ""
                }
                
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "photo")
                        .font(.title2)
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $selectedImage)
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.contactName.isEmpty ? "Loading..." : viewModel.contactName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchMessages(chatId: chatId)
            viewModel.fetchContactName(chatId: chatId, currentUserId: currentUserId)
        }
        .onDisappear { viewModel.detachListener() }
        .onChange(of: selectedImage) { image in
            if let image = image {
                viewModel.sendImageMessage(chatId: chatId, senderId: currentUserId, image: image)
                selectedImage = nil
            }
        }
    }
}

import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

/*
#Preview {
    ChatDetailView()
 }*/
