import SwiftUI
import SpriteKit

@main
struct BananaBlastApp: App {
    var body: some Scene {
        WindowGroup {
            GameHostView()
                .ignoresSafeArea()
                .statusBarHidden()
        }
    }
}

struct GameHostView: View {
    private var scene: SKScene {
        let scene = GameScene(size: CGSize(width: 960, height: 540))
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}
