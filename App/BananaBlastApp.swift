
import SwiftUI
import SpriteKit

@main
struct BananaBlastApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
        }
    }
}

struct ContentView: View {
    var body: some View {
        SpriteView(scene: createScene())
            .ignoresSafeArea()
    }

    private func createScene() -> SKScene {
        let scene = GameScene(
            size: CGSize(width: 852, height: 393)
        )
        scene.scaleMode = .resizeFill
        return scene
    }
}
