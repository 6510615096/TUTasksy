import SwiftUI
import Firebase

@main
struct TUTasksyApp: App {
    init() {
           FirebaseApp.configure()
       }
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
