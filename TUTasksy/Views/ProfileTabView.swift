import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct ProfileTabView: View {
    @State private var name = "Loading..."
    @State private var faculty = "Loading..."
    @State private var studentID = "Loading..."
    @State private var username = "Loading..."
    @State private var bio = "Loading..."
    @State private var profileInitial = "U"
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var profileImageUrl: String? = nil
    @State private var isLoadingImage = false
    
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
                    VStack {
                        HStack (spacing: 20) {
                            Spacer().frame(height: 50)
                            Button(action: {
                                // Handle chat
                            }) {
                                Image(systemName: "ellipsis.bubble")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            Button(action: {
                                // Handle report
                            }) {
                                Image(systemName: "flag")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            Spacer()
                        }
                        
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            ZStack {
                                if let image = profileImage {
                                    // Show profile image
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 130, height: 130)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                        .shadow(radius: 5)
                                } else if isLoadingImage {
                                    Circle()
                                        .fill(Color(hex: "#CAE5FF").opacity(1))
                                        .frame(width: 130, height: 130)
                                        .overlay(
                                            ProgressView()
                                                .foregroundColor(.white)
                                        )
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                        .shadow(radius: 5)
                                } else {
                                    //no image
                                    Circle()
                                        .fill(Color(hex: "#CAE5FF").opacity(1))
                                        .frame(width: 130, height: 130)
                                        .overlay(
                                            isLoading ?
                                                AnyView(ProgressView().foregroundColor(.white)) :
                                                AnyView(Text(profileInitial)
                                                    .font(.system(size: 50, weight: .semibold))
                                                    .fontDesign(.rounded)
                                                    .foregroundColor(.white))
                                        )
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                        .shadow(radius: 5)
                                }
                                
                                if !isLoading && !isLoadingImage {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color(hex: "#CAE5FF")))
                                        .offset(x: 45, y: 45)
                                }
                            }
                        }
                        .disabled(isLoading || isLoadingImage)
                        
                        Spacer().frame(height: 30)
                        
                        if isLoading {
                            VStack {
                                ProgressView()
                                    .padding()
                                Text("Loading your profile...")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 20) {
                                InfoField(label: "Full Name", text: name)
                                InfoField(label: "Faculty", text: faculty)
                                InfoField(label: "Student ID", text: studentID)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Username")
                                        .font(.headline)
                                    TextField("Enter username", text: $username)
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
                            
                            Spacer().frame(height: 20)
                            
                            // Action buttons
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
                            .disabled(isSaving)
                            
                            Button(action: {
                                do {
                                    try Auth.auth().signOut()
                                    isLoggedIn = false
                                } catch let signOutError as NSError {
                                    print("Error signing out: %@", signOutError)
                                    errorMessage = "Failed to sign out: \(signOutError.localizedDescription)"
                                    showError = true
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
            .background(Color(hex: "#ffffff").ignoresSafeArea())
            .onAppear(perform: fetchUserProfile)
            .onChange(of: selectedImage) { oldItem, newItem in
                Task {
                    guard let item = newItem else { return }
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImage = uiImage
                        }
                        await uploadProfileImage(data: data)
                    }
                }
            }
            .alert(isPresented: $showError, content: {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            })
            .refreshable {
                fetchUserProfile()
            }
        }
    }

    private func fetchUserProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            isLoading = false
            errorMessage = "No user is signed in"
            showError = true
            return
        }

        isLoading = true
        profileImage = nil
        profileImageUrl = nil

        let group = DispatchGroup()

        // Fetch from users collection
        group.enter()
        let userRef = db.collection("users").document(currentUser.uid)
        userRef.getDocument { document, error in
            defer { group.leave() }

            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    errorMessage = "Error fetching basic profile: \(error.localizedDescription)"
                    showError = true
                }
                return
            }

            guard let document = document, document.exists, let userData = document.data() else {
                print("User document doesn't exist")
                DispatchQueue.main.async {
                    errorMessage = "User profile not found"
                    showError = true
                }
                return
            }

            DispatchQueue.main.async {
                self.name = userData["displayname_en"] as? String ?? "Name not set"
                self.faculty = userData["faculty"] as? String ?? "Faculty not set"
                self.studentID = userData["username"] as? String ?? "ID not set"

                if let name = userData["displayname_en"] as? String, !name.isEmpty {
                    self.profileInitial = String(name.prefix(1)).uppercased()
                } else if let username = userData["username"] as? String, !username.isEmpty {
                    self.profileInitial = String(username.prefix(1)).uppercased()
                } else {
                    self.profileInitial = "U"
                }
            }
        }

        // Fetch from profiles collection
        group.enter()
        let profileRef = db.collection("profiles").document(currentUser.uid)
        profileRef.getDocument { document, error in
            defer { group.leave() }

            if let error = error {
                print("Error fetching extended profile: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    errorMessage = "Error fetching extended profile: \(error.localizedDescription)"
                    showError = true
                }
                return
            }

            if let document = document, document.exists, let profileData = document.data() {
                DispatchQueue.main.async {
                    self.username = profileData["nickname"] as? String ?? "Username not set"
                    self.bio = profileData["bio"] as? String ?? ""
                    self.profileImageUrl = profileData["profileImageUrl"] as? String
                }

                // Load profile image if URL exists
                if let urlString = profileData["profileImageUrl"] as? String, !urlString.isEmpty {
                    print("Profile Image URL: \(urlString)")
                    loadProfileImage(from: urlString)
                }
            } else {
                print("Extended profile document doesn't exist yet")
                DispatchQueue.main.async {
                    errorMessage = "Profile data is incomplete. Please complete your profile."
                    showError = true
                }
            }
        }

        group.notify(queue: .main) {
            isLoading = false
        }
    }

    
    private func loadProfileImage(from urlString: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user signed in")
            return
        }

        DispatchQueue.main.async {
            self.isLoadingImage = true
        }

        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: urlString)

        // Adjust maxSize if your images are large
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                self.isLoadingImage = false
            }

            if let error = error {
                print("Firebase Storage image download failed: \(error.localizedDescription)")
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("Could not decode image from Firebase data")
                return
            }

            DispatchQueue.main.async {
                self.profileImage = image
            }
        }
    }

    private func saveProfile() {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "No user is signed in"
            showError = true
            return
        }
        
        isSaving = true
        focusedField = nil

        let profileRef = db.collection("profiles").document(currentUser.uid)
        profileRef.setData([
            "profileImageUrl": profileImageUrl ?? "",
            "nickname": username,
            "bio": bio,
            "lastUpdated": FieldValue.serverTimestamp()
        ], merge: true) { error in
            DispatchQueue.main.async {
                isSaving = false
                
                if let error = error {
                    print("Error saving profile: \(error.localizedDescription)")
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    showError = true
                } else {
                    print("Profile updated successfully in 'profiles'")
                    withAnimation {
                        //
                    }
                }
            }
        }
    }

    private func uploadProfileImage(data: Data) async {
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                errorMessage = "No user is signed in"
                showError = true
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isLoadingImage = true
        }

        let storageRef = Storage.storage().reference().child("profileImages/\(currentUser.uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        do {
            guard let compressedData = UIImage(data: data)?
                .jpegData(compressionQuality: 0.7) else {
                throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            let _ = try await storageRef.putDataAsync(compressedData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            
            DispatchQueue.main.async {
                self.profileImageUrl = downloadURL.absoluteString
                self.isLoadingImage = false
            }

            try await db.collection("profiles").document(currentUser.uid).setData([
                "profileImageUrl": downloadURL.absoluteString,
                "lastUpdated": FieldValue.serverTimestamp()
            ], merge: true)

            print("Profile image uploaded and URL saved to 'profiles'")
        } catch {
            print("Error uploading profile image: \(error.localizedDescription)")
            DispatchQueue.main.async {
                errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
                showError = true
                self.isLoadingImage = false
            }
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
