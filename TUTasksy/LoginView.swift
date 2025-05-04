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
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color(hex: "#CAE5FF")
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Image("Logo")
                    .resizable()
                    .frame(width: 250, height: 250)
                    //.padding()
                VStack(spacing: 20) {
                    Text("TU Student ID")
                        .foregroundColor(Color(hex: "#C77A17"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .padding(.top)

                    TextField("Student ID", text: $email)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Text("Passsword")
                        .foregroundColor(Color(hex: "#C77A17"))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .padding(.top)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    
                    Spacer()

                    Button(action: {
                        // waiting for action
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

                    Spacer()
                }
                .padding()
                .frame(width: 350, height: 450)
                .background(Color(hex: "#FFFAED"))
                .cornerRadius(20)
                //.shadow(radius: 5)
            }
        }
    }
}


#Preview {
    LoginView()
}
