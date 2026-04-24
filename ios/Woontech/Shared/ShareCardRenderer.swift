import SwiftUI
import UIKit

/// Renders a SwiftUI view into a 1080×1920 UIImage for 공유 카드(IG 스토리 규격).
/// NFC-9.
enum ShareCardRenderer {
    static let size = CGSize(width: 1080, height: 1920)

    @MainActor
    static func renderImage<Content: View>(@ViewBuilder _ content: () -> Content) -> UIImage? {
        let view = content()
            .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0 // intrinsic 1080×1920
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        return renderer.uiImage
    }
}
