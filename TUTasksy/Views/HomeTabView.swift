import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct HomeTabView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showCreateTask = false
    
    var body: some View {
        ZStack {
            Color(.white)
            // แสดง task ทั้งหมดในหน้า home
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
            
            // ปุ่มสร้าง task ใหม่
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


/*
#Preview {
    HomeTabView()
}*/
