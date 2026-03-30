//
//  ParallaxHeroImage.swift
//  Days
//

import SwiftUI

struct ParallaxHeroImage: View {
    let image: UIImage
    let height: CGFloat

    init(image: UIImage, height: CGFloat = 280) {
        self.image = image
        self.height = height
    }

    var body: some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .scrollView).minY
            ZStack {
                Color.black

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: height + max(offset, 0))
                    .offset(y: offset > 0 ? -offset : offset * -0.2)
            }
            .frame(width: geo.size.width, height: height + max(offset, 0))
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [.clear, Color(.systemBackground).opacity(0.9)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
        .frame(height: height)
    }
}
