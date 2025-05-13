import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#") // ข้าม #
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}

struct LoginView: View {
    @State private var studentid = ""
    @State private var password = ""
    @StateObject private var viewModel = LoginViewModel()
    @State private var navigationPath = NavigationPath()
    //@AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(hex: "#CAE5FF").ignoresSafeArea()

                VStack {
                    Image("Logo")
                        .resizable()
                        .frame(width: 250, height: 250)

                    VStack(spacing: 20) {
                        Text("TU Student ID")
                            .foregroundColor(Color(hex: "#C77A17"))
                            .fontDesign(.rounded)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top)

                        TextField("Student ID", text: $studentid)
                            .padding()
                            .fontDesign(.rounded)
                            .background(Color.white)
                            .cornerRadius(10)

                        Text("Password")
                            .foregroundColor(Color(hex: "#C77A17"))
                            .font(.title2)
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)

                        if viewModel.isLoading {
                            ProgressView()
                        }
                        
                        Button(action: {
                            viewModel.loginWithTuApi(studentid: studentid, password: password)
                        }) {
                            Text("Sign In")
                                .foregroundColor(Color(hex: "#C77A17"))
                                .padding()
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "#FFE7E4"))
                                .cornerRadius(10)
                                .shadow(radius: 3, x: 0, y: 3)
                        }

                        if !viewModel.loginMessage.isEmpty {
                            Text(viewModel.loginMessage)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                    .background(Color(hex: "#FFFAED"))
                    .cornerRadius(20)
                    .frame(width: 350, height: 450)
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "home" {
                    HomeView()
                        .navigationBarBackButtonHidden(true)
                }
            }
            .onChange(of: viewModel.isLoggedIn) {
                if viewModel.isLoggedIn {
                    navigationPath.append("home")
                }
            }
        }
    }
}


#Preview {
    LoginView()
}
