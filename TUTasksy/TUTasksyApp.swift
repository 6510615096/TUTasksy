import SwiftUI
import Firebase

@main
struct TUTasksyApp: App {
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    init() {
           FirebaseApp.configure()
       }
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}
