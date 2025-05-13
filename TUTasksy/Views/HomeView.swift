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
    @State private var isBanned: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true

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
            if isBanned {
                VStack {
                    Spacer()
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .padding()
                    Text("Your account was banned.\n Please contact the administrator.\n TUTasksy@gmail.com")
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .foregroundColor(.red)
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            isLoggedIn = false
                        } catch let signOutError as NSError {
                            print("Error signing out: %@", signOutError)
                        }
                    
                    }) {
                        Text("Log Out")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                            .padding(.top, 16)
                    }
                    Spacer()
                }
            } else {
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
            }
        }
        .onAppear {
            checkIfAdminAndBanned()
        }
    }

    private func checkIfAdminAndBanned() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { document, error in
            if let document = document, document.exists {
                let isAdmin = document.data()?["admin"] as? Bool ?? false
                let isBanned = document.data()?["isBanned"] as? Bool ?? false
                self.isAdmin = isAdmin
                self.isBanned = isBanned
            }
        }
    }
}

#Preview {
    HomeView()
}
