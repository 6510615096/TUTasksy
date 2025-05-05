import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth
import PhotosUI

struct CreateTaskView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var reward = ""
    @State private var image: UIImage? = nil
    @State private var isUploading = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var userNickname = ""
    @Environment(\.dismiss) var dismiss
    
    private var today: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss()
                    }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                VStack(spacing: 0) {
                    HeaderView(title: "CREATE TASK")
                    //Spacer()
                }
                //Spacer()
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 35))
            .background(Color.blue.opacity(0.2))

            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        Circle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .overlay(Text("-").font(.headline).foregroundColor(.white))
                        VStack(alignment: .leading) {
                            Text(userNickname.isEmpty ? "Loading..." : userNickname)
                                .font(.headline)
                                .foregroundColor(.brown)
                            Text(today)
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Text("Available")
                            .font(.caption)
                            .padding(6)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Group {
                        Text("Title")
                            .fontWeight(.semibold)
                        TextField("Enter task title", text: $title)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)

                        Text("Description")
                            .fontWeight(.semibold)
                        TextField("Enter task description", text: $description, axis: .vertical)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .lineLimit(3...)

                        Text("Reward")
                            .fontWeight(.semibold)
                        TextField("Enter reward amount", text: $reward)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                            .keyboardType(.numberPad)

                        Text("Picture (optional)")
                            .fontWeight(.semibold)
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(radius: 1)
                                .frame(height: 150)

                            if let image = image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .cornerRadius(16)
                            } else {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Image(systemName: "camera")
                                        .font(.largeTitle)
                                        .foregroundColor(.black)
                                }
                                .onChange(of: selectedItem) {
                                    Task {
                                        if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            self.image = uiImage
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button(action: {
                        uploadTask()
                    }) {
                        Text("Create Task")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(16)
                            //.shadow(radius: 2)
                    }
                    .disabled(isUploading)

                    if isUploading {
                        ProgressView()
                    }
                }
                .padding()
                .background(Color(red: 1.0, green: 0.98, blue: 0.94))
                .cornerRadius(24)
                .padding()
            }
        }
        .onAppear {
            fetchUserNickname()
        }
    }

    func uploadTask() {
        guard !title.isEmpty, !description.isEmpty, !reward.isEmpty else { return }
        isUploading = true

        guard let user = Auth.auth().currentUser else {
            isUploading = false
            return
        }

        let db = Firestore.firestore()

        db.collection("users").document(user.uid).getDocument { document, error in
            guard let document = document, document.exists,
                  let data = document.data(),
                  let nickname = data["nickname"] as? String else {
                print("Failed to get nickname")
                isUploading = false
                return
            }

            var taskData: [String: Any] = [
                "title": title,
                "description": description,
                "reward": reward,
                "date": Timestamp(date: Date()),
                "userId": user.uid,
                "username": nickname,
                "status": "Available"
            ]

            func saveToFirestore(imageUrl: String? = nil) {
                if let url = imageUrl {
                    taskData["imageUrl"] = url
                }
                db.collection("tasks").addDocument(data: taskData) { error in
                    isUploading = false
                    if let error = error {
                        print("Error uploading task: \(error)")
                    } else {
                        print("Task uploaded successfully!")
                        title = ""
                        description = ""
                        reward = ""
                        image = nil
                    }
                }
            }

            if let image = image {
                uploadImage(image: image) { url in
                    saveToFirestore(imageUrl: url)
                }
            } else {
                saveToFirestore()
            }
        }
    }

    func uploadImage(image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference().child("task_images/\(UUID().uuidString).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Upload image error: \(error)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                completion(url?.absoluteString)
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
}

#Preview {
    CreateTaskView()
}
