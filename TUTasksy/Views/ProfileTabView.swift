import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct ProfileTabView: View {
    @State private var name = "Name Surname"
    @State private var faculty = "Faculty"
    @State private var studentID = "Student ID"
    @State private var username = "Username"
    @State private var bio = "Bio"
    @State private var profileInitial = "upload"
    @State private var isLoading = true
    @State private var isSaving = false

    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    @FocusState private var focusedField: Field?
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true

    enum Field: Hashable {
        case username
        case bio
    }

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 30)
                        
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            ZStack {
                                if let image = profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 130, height: 130)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 5)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 130, height: 130)
                                        .overlay(
                                            isLoading ? AnyView(ProgressView()) :
                                                AnyView(Text(profileInitial)
                                                    .font(.system(size: 20, weight: .medium))
                                                    .fontDesign(.rounded)
                                                    .foregroundColor(.white))
                                        )
                                        .shadow(radius: 5)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 15) {
                            InfoField(label: "Full Name", text: name)
                            InfoField(label: "Faculty", text: faculty)
                            InfoField(label: "Student ID", text: studentID)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Username")
                                    .font(.headline)
                                TextField("Enter username", text: $username)
                                    //.textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(10)
                                    .background(Color(hex: "#FFEBE8"))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    .focused($focusedField, equals: .username)
                                    .scrollContentBackground(.hidden)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Bio")
                                    .font(.headline)
                                TextEditor(text: $bio)
                                    .frame(height: 120)
                                    .padding(10)
                                    .background(Color(hex: "#FFEBE8"))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    .focused($focusedField, equals: .bio)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: saveProfile) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save Profile")
                                }
                            }
                            .foregroundColor(Color(hex: "#C77A17"))
                            .padding()
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FFE7E4"))
                            .cornerRadius(10)
                            .shadow(radius: 2, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            do {
                                try Auth.auth().signOut()
                                isLoggedIn = false
                            } catch let signOutError as NSError {
                                print("Error signing out: %@", signOutError)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.backward.circle")
                                Text("Logout")
                            }
                            .foregroundColor(.red)
                            .padding()
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#E7E7E7"))
                            .cornerRadius(10)
                            .shadow(radius: 2, x: 0, y: 3)
                        }
                        .padding()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(hex: "#FFFAED"))
                            .cornerRadius(20)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    .padding()
                }
            }
            .background(Color(hex: "#ffffff").ignoresSafeArea()) //FFFAED
           // .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: fetchUserProfile)
            .onChange(of: selectedImage) { oldItem, newItem in
                Task {
                    guard let item = newItem else { return }
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        self.profileImage = uiImage
                        await uploadProfileImage(data: data)
                    }
                }
            }

        }
    }

    private func fetchUserProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        let userRef = db.collection("users").document(currentUser.uid)

        userRef.getDocument { document, error in
            isLoading = false
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }
            guard let document = document, document.exists, let userData = document.data() else {
                print("User document doesn't exist")
                return
            }
            DispatchQueue.main.async {
                self.name = userData["displayname_en"] as? String ?? "Name not set"
                self.faculty = userData["faculty"] as? String ?? "Faculty not set"
                self.studentID = userData["username"] as? String ?? "Student ID not set"
                self.username = userData["nickname"] as? String ?? "Username not set"
                self.bio = userData["bio"] as? String ?? "Bio not set"
                if let name = userData["name"] as? String, !name.isEmpty {
                    self.profileInitial = String(name.prefix(1))
                }
                if let urlString = userData["profileImageUrl"] as? String,
                   let url = URL(string: urlString) {
                    Task {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                self.profileImage = image
                            }
                        } catch {
                            print("Error loading profile image from URL: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }

    private func saveProfile() {
        guard let currentUser = Auth.auth().currentUser else { return }
        isSaving = true
        focusedField = nil

        let userRef = db.collection("users").document(currentUser.uid)
        userRef.updateData([
            "nickname": username,
            "bio": bio
        ]) { error in
            isSaving = false
            if let error = error {
                print("Error saving profile: \(error.localizedDescription)")
            } else {
                print("Profile updated successfully")
            }
        }
    }

    private func uploadProfileImage(data: Data) async {
        guard let currentUser = Auth.auth().currentUser else { return }

        let storageRef = Storage.storage().reference().child("profileImages/\(currentUser.uid).jpg")

        do {
            let _ = try await storageRef.putDataAsync(data, metadata: nil)
            let downloadURL = try await storageRef.downloadURL()
            try await db.collection("users").document(currentUser.uid).updateData([
                "profileImageUrl": downloadURL.absoluteString
            ])
            print("Profile image uploaded and URL saved.")
        } catch {
            print("Error uploading profile image: \(error.localizedDescription)")
        }
    }
}

struct InfoField: View {
    var label: String
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.headline)
            Text(text)
                .font(.body)
                .fontDesign(.rounded)
                .foregroundColor(.secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#FFFAED"))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2)))
        }
    }
}

#Preview {
    ProfileTabView()
}
