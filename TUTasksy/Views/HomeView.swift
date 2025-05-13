import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }

        guard hexFormatted.count == 6,
              let rgbValue = UInt64(hexFormatted, radix: 16) else {
            return nil
        }

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}


struct HeaderView: View {
    var title: String
    
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .multilineTextAlignment(.center)
            .fontDesign(.rounded)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity,maxHeight: 70, alignment: .bottom)
            .background(Color(hex: "#CAE5FF"))
            .foregroundColor(Color(hex: "#C77A17"))
    }
}

enum Tab {
    case home, tasks, chats, profile, admin
}

struct HomeView: View {
    
    @State private var selectedTab: Tab = .home
    @State private var isAdmin: Bool = false
    
    init() {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(hex: "#CAE5FF")

            UITabBar.appearance().standardAppearance = tabBarAppearance

            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    
    var headerTitle: String {
           switch selectedTab {
           case .home: return "HOME"
           case .tasks: return "TASKS"
           case .chats: return "CHATS"
           case .profile: return "PROFILE"
           case .admin: return "ADMIN REPORTS"
           }
       }

    var body: some View {
            VStack(spacing: 0) {
                HeaderView(title: headerTitle)
                //Spacer()
            }
            //.ignoresSafeArea(edges: .top)
        
            // tab ข้างล่าง link ไปแต่ละหน้า
            TabView(selection: $selectedTab) {
                HomeTabView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(Tab.home)

                TasksTabView()
                    .tabItem {
                        Label("Tasks", systemImage: "briefcase")
                    }
                    .tag(Tab.tasks)

                if let user = Auth.auth().currentUser {
                    ChatsTabView(currentUserId: user.uid)
                        .tabItem {
                            Label("Chats", systemImage: "ellipses.bubble")
                        }
                        .tag(Tab.chats)
                } else {
                    // Show login view or placeholder
                    Text("Please log in to view chats.")
                        .tabItem {
                            Label("Chats", systemImage: "ellipses.bubble")
                        }
                        .tag(Tab.chats)
                }
                
                if isAdmin {
                    AdminReportsTabView()
                        .tabItem {
                            Label("Admin", systemImage: "shield")
                        }
                        .tag(Tab.admin)
                }

                ProfileTabView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(Tab.profile)
            }
            .accentColor(Color(hex: "#C77A17"))
            .onAppear {
                checkIfAdmin()
            }
        }
    private func checkIfAdmin() {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                let isAdmin = document.data()?["admin"] as? Bool ?? false
                self.isAdmin = isAdmin
            }
        }
    }
}

#Preview {
    HomeView()
}
