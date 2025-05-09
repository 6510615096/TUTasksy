import SwiftUI

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(task.username.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
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
            
            if let imageUrl = task.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        Image(systemName: "photo")
                            .frame(height: 200)
                    @unknown default:
                        EmptyView()
                    }
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
                    
                    // Handle comment
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
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeTabView()
}
