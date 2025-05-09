import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


class LoginViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var loginMessage = ""
    //@Published var isLoggedIn = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false


    func loginWithTuApi(studentid: String, password: String) {
        isLoading = true
        loginMessage = ""

        guard let url = URL(string: "http://localhost:3000/login") else {
            self.loginMessage = "Invalid backend URL"
            self.isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["studentid": studentid, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.loginMessage = "Network error: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }

                guard let data = data else {
                    self.loginMessage = "No data received"
                    self.isLoading = false
                    return
                }

                if let jsonString = String(data: data, encoding: .utf8) {
                   // print("Response Data: \(jsonString)")
                }

                do {
                    struct ErrorResponse: Decodable {
                        let message: String
                    }

                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        self.loginMessage = errorResponse.message
                        self.isLoading = false
                        return
                    }

                    struct Response: Decodable {
                        let token: String
                        let userInfo: UserInfo
                    }

                    let decoded = try JSONDecoder().decode(Response.self, from: data)

                    Auth.auth().signIn(withCustomToken: decoded.token) { result, error in
                        if let error = error {
                            self.loginMessage = "Firebase login error: \(error.localizedDescription)"
                            self.isLoading = false
                        } else {
                            self.isLoggedIn = true
                            self.saveUserData(userInfo: decoded.userInfo)
                        }
                    }

                } catch {
                   // print("Decoding error: \(error)")
                    self.loginMessage = "Failed to parse login response: \(error.localizedDescription)"
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
            "username": userInfo.username,
            "displayname_th": userInfo.displayname_th,
            "displayname_en": userInfo.displayname_en,
            "email": userInfo.email,
            "type": userInfo.type,
            "department": userInfo.department,
            "faculty": userInfo.faculty,
            //"nickname": "not set",
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

