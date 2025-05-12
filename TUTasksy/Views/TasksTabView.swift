import SwiftUI
import FirebaseAuth

enum TaskFilter: String, CaseIterable {
    case created = "Created"
    case accepted = "Accepted"
    case favorites = "Favorites"
}

struct TasksTabView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var selectedFilter: TaskFilter = .created

    var body: some View {
        NavigationView {
            VStack {
                Picker("Task Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTasks()) { task in
                            TaskCardView(task: task)
                        }
                    }
                    .padding()
                }
              //  .navigationTitle("My Tasks")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            viewModel.fetchTasks()
        }
    }

    func filteredTasks() -> [TaskCard] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }

        switch selectedFilter {
        case .created:
            return viewModel.tasks.filter { $0.userId == currentUserId }

        case .accepted:
            return viewModel.tasks.filter { $0.acceptedUserIds.contains(currentUserId) }

        case .favorites:
            return viewModel.tasks.filter { $0.likeUserIds.contains(currentUserId) }
        }
    }
}


#Preview {
    TasksTabView()
}
