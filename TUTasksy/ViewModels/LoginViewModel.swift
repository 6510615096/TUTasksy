import Foundation
import FirebaseAuth
import FirebaseFirestore


class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var loginMessage = ""
    @Published var isLoggedIn = false

    func loginWithTuApi(studentid: String, password: String) {
        isLoading = true
        loginMessage = ""
        isLoggedIn = false

        guard let url = URL(string: "https://restapi.tu.ac.th/api/v1/auth/Ad/verify") else {
            self.loginMessage = "Invalid API URL"
            self.isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("", forHTTPHeaderField: "Application-Key")

        let body = ["UserName": studentid, "PassWord": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.loginMessage = "No response from server"
                    self.isLoading = false
                    return
                }

                if httpResponse.statusCode == 200, let data = data {
                    do {
                        let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
                        self.signInToFirebase(with: userInfo)
                    } catch {
                        self.loginMessage = "Failed to parse user info"
                        self.isLoading = false
                    }
                } else {
                    self.loginMessage = "Login failed. Code: \(httpResponse.statusCode)"
                    self.isLoading = false
                }
            }
        }.resume()

    }

    private func signInToFirebase(with userInfo: UserInfo) {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                self.loginMessage = "Firebase login error: \(error.localizedDescription)"
                self.isLoading = false
            } else {
                self.saveUserData(userInfo: userInfo)
            }
        }
    }


    private func saveUserData(userInfo: UserInfo) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "displayname_th": userInfo.displayname_th,
            "displayname_en": userInfo.displayname_en,
            "email": userInfo.email,
            "username": userInfo.username,
            "type": userInfo.type,
            "department": userInfo.department,
            "faculty": userInfo.faculty,
            "createdAt": FieldValue.serverTimestamp()
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.loginMessage = "Firestore error: \(error.localizedDescription)"
                } else {
                    self.isLoggedIn = true
                }
                self.isLoading = false
            }
        }
    }

}

