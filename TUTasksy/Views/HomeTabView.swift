import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct HomeTabView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showCreateTask = false
    
    var body: some View {
        ZStack {
            Color(.white)
            
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.tasks) { task in
                            TaskCardView(task: task)
                        }
                    }
                    .padding()
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCreateTask = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundColor(Color(hex: "#C77A17"))
                            .frame(width: 60, height: 60)
                            .background(Color(hex: "#FFE7E4"))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showCreateTask) {
            CreateTaskView()
        }
        .onAppear {
            viewModel.fetchTasks()
        }
    }
}

struct TaskCardView: View {
    let task: TaskCard
    @State private var isPressed = false
    @State private var showCommentPanel = false
    @State private var taskImage: UIImage? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isLoadingTaskImage = false
    @State private var isLoadingProfileImage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
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
            
            Text("Reward: \(task.reward)")
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundColor(.orange)
                .padding(.top, 4)
            
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
                // Interest button
                Button(action: {
                    // Handle interest action
                }) {
                    Text("กดสนใจงานนี้")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.pink.opacity(0.8))
                        .cornerRadius(20)
                }
                
                Spacer()
                
                // Like button
                Button(action: {
                    // Handle like
                }) {
                    Image(systemName: "heart")
                        .font(.title3)
                        .foregroundColor(.pink.opacity(0.5))
                }
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
                    // Handle report
                }) {
                    Image(systemName: "flag")
                        .font(.title3)
                        .foregroundColor(.gray.opacity(0.5))
                }
                .padding(.horizontal, 8)
            }
        }
        .padding()
        .background(Color(hex: "#FFFAED"))
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        .onAppear {
            loadProfileImage(for: task.userId)
        }
    }
    
    private func loadTaskImage(from urlString: String) {
        guard !urlString.isEmpty else { return }
        
        isLoadingTaskImage = true
        let storageRef = Storage.storage().reference(forURL: urlString)
        
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            isLoadingTaskImage = false
            if let error = error {
                print("Error loading task image: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                self.taskImage = image
            }
        }
    }
    
    private func loadProfileImage(for userId: String) {
        guard !userId.isEmpty else { return }
        
        isLoadingProfileImage = true
        let db = Firestore.firestore()
        
        // Fetch the profile document for the given userId
        db.collection("profiles").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching profile document: \(error.localizedDescription)")
                isLoadingProfileImage = false
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let profileImageUrl = data["profileImageUrl"] as? String else {
                print("No profile image URL found for userId: \(userId)")
                isLoadingProfileImage = false
                return
            }
            
            // Load the profile image from Firebase Storage
            let storageRef = Storage.storage().reference(forURL: profileImageUrl)
            storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                isLoadingProfileImage = false
                if let error = error {
                    print("Error loading profile image: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    self.profileImage = image
                }
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
    HomeTabView()
}*/
