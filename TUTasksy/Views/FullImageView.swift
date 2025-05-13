//
//  File.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 13/5/2568 BE.
//

import Foundation
import SwiftUI
import FirebaseStorage

struct FullImageView: View {
    let imageUrl: String

    @State private var image: UIImage? = nil
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("ไม่พบภาพ")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            loadImageFromFirebaseStorage(urlString: imageUrl)
        }
    }

    private func loadImageFromFirebaseStorage(urlString: String) {
        guard !urlString.isEmpty else {
            isLoading = false
            return
        }
        isLoading = true
        let storageRef = Storage.storage().reference(forURL: urlString)
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = uiImage
                }
                self.isLoading = false
            }
        }
    }
}
