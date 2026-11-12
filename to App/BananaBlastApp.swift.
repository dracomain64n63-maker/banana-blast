import SwiftUI
import SpriteKit

@main
struct BananaBlastApp: App {
    var body: some Scene {
        WindowGroup {
            GameHostView()
                .ignoresSafeArea()
                .statusBarHidden()
                .preferredColorScheme(.dark)
        }
    }
}

struct GameHostView: View {
    var body: some View {
        GeometryReader { proxy in
            SpriteView(
                scene: GameScene(size: CGSize(width: max(proxy.size.width, proxy.size.height),
                                               height: min(proxy.size.width, proxy.size.height))),
                options: [.ignoresSiblingOrder]
            )
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}
