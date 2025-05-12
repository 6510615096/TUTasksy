import SwiftUI

struct MessageBubble: View {
    let message: Message
    let currentUserId: String

    var body: some View {
        HStack {
            if message.senderId == currentUserId {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color(hex: "#FFFAED"))
                    .foregroundColor(Color.black)
                    .cornerRadius(20)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(Color.black)
                    .cornerRadius(20)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}


/*
#Preview {
    MessageBubble()
}*/
