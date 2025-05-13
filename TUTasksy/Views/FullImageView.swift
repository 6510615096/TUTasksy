//
//  File.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 13/5/2568 BE.
//

import Foundation
import SwiftUI

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
            loadImage(from: imageUrl)
        }
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let uiImage = UIImage(data: data) {
                    image = uiImage
                }
                isLoading = false
            }
        }
        .resume()
    }
}
