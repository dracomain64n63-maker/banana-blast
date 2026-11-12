
import SpriteKit
import UIKit

final class GameScene: SKScene {

    private enum GameState {
        case menu
        case playing
        case paused
        case gameOver
    }

    private var gameState: GameState = .menu

    private var score = 0
    private var coins = 0
    private var health = 3
    private var wave = 1
    private var combo = 0
    private var bestScore = UserDefaults.standard.integer(forKey: "bananaBlastBest")

    private var monkeys: [SKNode] = []
    private var bananas: [SKNode] = []

    private var lastUpdate: TimeInterval = 0
    private var spawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 2.0

    private var scoreLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    private var coinLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var crosshair: SKShapeNode!

    private var aimPoint = CGPoint.zero

    private let jungleGreen = UIColor(red: 0.04, green: 0.20, blue: 0.11, alpha: 1)
    private let bananaYellow = UIColor(red: 1.0, green: 0.82, blue: 0.12, alpha: 1)

    override func didMove(to view: SKView) {
        backgroundColor = jungleGreen
        scaleMode = .resizeFill
        showMenu()
    }

    // MARK: - Scene

    private func clearScene() {
        removeAllChildren()
        monkeys.removeAll()
        bananas.removeAll()
    }

    private func addLabel(
        _ text: String,
        size: CGFloat,
        position: CGPoint,
        color: UIColor = .white
    ) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.position = position
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)
        return label
    }

    private func addButton(
        _ title: String,
        name: String,
        position: CGPoint,
        size: CGSize
    ) {
        let button = SKShapeNode(
            rectOf: size,
            cornerRadius: 14
        )

        button.name = name
        button.position = position
        button.fillColor = UIColor(red: 0.12, green: 0.48, blue: 0.22, alpha: 1)
        button.strokeColor = .white
        button.lineWidth = 2
        button.zPosition = 100
        addChild(button)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = title
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = .zero
        label.name = name
        button.addChild(label)
    }

    private func addBackground() {
        let sky = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        sky.fillColor = UIColor(red: 0.12, green: 0.32, blue: 0.18, alpha: 1)
        sky.strokeColor = .clear
        sky.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sky.zPosition = -20
        addChild(sky)

        let path = SKShapeNode()
        let pathPoints = CGMutablePath()
        pathPoints.move(to: CGPoint(x: size.width * 0.38, y: 0))
        pathPoints.addLine(to: CGPoint(x: size.width * 0.62, y: 0))
        pathPoints.addLine(to: CGPoint(x: size.width * 0.53, y: size.height))
        pathPoints.addLine(to: CGPoint(x: size.width * 0.47, y: size.height))
        pathPoints.closeSubpath()

        path.path = pathPoints
        path.fillColor = UIColor(red: 0.48, green: 0.32, blue: 0.16, alpha: 1)
        path.strokeColor = .clear
        path.zPosition = -10
        addChild(path)

        for side in [-1.0, 1.0] {
            for index in 0..<9 {
                let tree = SKShapeNode(
                    circleOfRadius: CGFloat(18 + index * 2)
                )
                tree.fillColor = index % 2 == 0
                    ? UIColor(red: 0.04, green: 0.30, blue: 0.12, alpha: 1)
                    : UIColor(red: 0.08, green: 0.40, blue: 0.16, alpha: 1)

                tree.strokeColor = .clear
                tree.position = CGPoint(
                    x: size.width / 2 + CGFloat(side) * CGFloat(160 + index * 12),
                    y: CGFloat(index) * size.height / 9
                )
                tree.zPosition = -5
                addChild(tree)
            }
        }
    }

    // MARK: - Menu

    private func showMenu() {
        clearScene()
        gameState = .menu
        addBackground()

        addLabel(
            "BANANA BLAST",
            size: 42,
            position: CGPoint(x: size.width / 2, y: size.height * 0.72),
            color: bananaYellow
        )

        addLabel(
            "FIRST-PERSON JUNGLE ARCADE",
            size: 15,
            position: CGPoint(x: size.width / 2, y: size.height * 0.62)
        )

        addLabel(
            "BEST SCORE: \(bestScore)",
            size: 17,
            position: CGPoint(x: size.width / 2, y: size.height * 0.49)
        )

        addButton(
            "PLAY",
            name: "playButton",
            position: CGPoint(x: size.width / 2, y: size.height * 0.34),
            size: CGSize(width: 190, height: 60)
        )
    }

    // MARK: - Game

    private func startGame() {
        clearScene()
        gameState = .playing

        score = 0
        coins = 0
        health = 3
        wave = 1
        combo = 0

        spawnTimer = 0
        spawnInterval = 2.0
        lastUpdate = 0

        addBackground()
        createHUD()
        createHands()
        createCrosshair()
        updateHUD()
    }

    private func createHUD() {
        scoreLabel = addLabel(
            "SCORE: 0",
            size: 19,
            position: CGPoint(x: 95, y: size.height - 38)
        )
        scoreLabel.horizontalAlignmentMode = .left

        waveLabel = addLabel(
            "WAVE 1",
            size: 19,
            position: CGPoint(x: size.width / 2, y: size.height - 38)
        )

        healthLabel = addLabel(
            "♥ ♥ ♥",
            size: 22,
            position: CGPoint(x: size.width - 100, y: size.height - 38),
            color: .systemRed
        )

        coinLabel = addLabel(
            "COINS: 0",
            size: 15,
            position: CGPoint(x: 85, y: size.height - 65)
        )
        coinLabel.horizontalAlignmentMode = .left

        comboLabel = addLabel(
            "",
            size: 20,
            position: CGPoint(x: size.width / 2, y: size.height * 0.72),
            color: bananaYellow
        )

        addButton(
            "THROW",
            name: "throwButton",
            position: CGPoint(x: size.width - 105, y: 75),
            size: CGSize(width: 150, height: 62)
        )

        addButton(
            "BURST",
            name: "burstButton",
            position: CGPoint(x: size.width - 270, y: 75),
            size: CGSize(width: 105, height: 48)
        )

        addButton(
            "Ⅱ",
            name: "pauseButton",
            position: CGPoint(x: size.width - 35, y: size.height - 85),
            size: CGSize(width: 48, height: 42)
        )
    }

    private func createHands() {
        let sleeve = SKShapeNode(
            rectOf: CGSize(width: 230, height: 90),
            cornerRadius: 30
        )
        sleeve.fillColor = UIColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1)
        sleeve.strokeColor = .clear
        sleeve.position = CGPoint(x: size.width / 2, y: 22)
        sleeve.zPosition = 40
        addChild(sleeve)

        let hand = SKShapeNode(
            ellipseOf: CGSize(width: 115, height: 55)
        )
        hand.fillColor = UIColor(red: 0.77, green: 0.48, blue: 0.29, alpha: 1)
        hand.strokeColor = .clear
        hand.position = CGPoint(x: size.width / 2, y: 88)
        hand.zPosition = 41
        addChild(hand)

        let banana = SKShapeNode(
            ellipseOf: CGSize(width: 100, height: 27)
        )
        banana.fillColor = bananaYellow
        banana.strokeColor = UIColor(red: 0.75, green: 0.53, blue: 0.05, alpha: 1)
        banana.lineWidth = 3
        banana.position = CGPoint(x: size.width / 2, y: 130)
        banana.zRotation = 0.25
        banana.zPosition = 42
        addChild(banana)
    }

    private func createCrosshair() {
        crosshair = SKShapeNode(circleOfRadius: 17)
        crosshair.strokeColor = .white
        crosshair.lineWidth = 2
        crosshair.fillColor = .clear
        crosshair.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        crosshair.zPosition = 60
        addChild(crosshair)

        let horizontal = SKShapeNode(
            rectOf: CGSize(width: 30, height: 2)
        )
        horizontal.fillColor = .white
        horizontal.strokeColor = .clear
        crosshair.addChild(horizontal)

        let vertical = SKShapeNode(
            rectOf: CGSize(width: 2, height: 30)
        )
        vertical.fillColor = .white
        vertical.strokeColor = .clear
        crosshair.addChild(vertical)
    }

    // MARK: - Monkeys

    private func spawnMonkey() {
        let monkey = SKNode()

        let body = SKShapeNode(
            ellipseOf: CGSize(width: 65, height: 78)
        )
        body.fillColor = UIColor(red: 0.40, green: 0.22, blue: 0.12, alpha: 1)
        body.strokeColor = .black
        body.lineWidth = 2
        monkey.addChild(body)

        let face = SKShapeNode(
            ellipseOf: CGSize(width: 43, height: 43)
        )
        face.fillColor = UIColor(red: 0.85, green: 0.63, blue: 0.42, alpha: 1)
        face.strokeColor = .clear
        face.position = CGPoint(x: 0, y: 13)
        monkey.addChild(face)

        for eyeX in [-9.0, 9.0] {
            let eye = SKShapeNode(circleOfRadius: 3)
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.position = CGPoint(x: eyeX, y: 17)
            monkey.addChild(eye)
        }

        let mouth = SKShapeNode(
            ellipseOf: CGSize(width: 15, height: 5)
        )
        mouth.fillColor = .black
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 0, y: 2)
        monkey.addChild(mouth)

        let tail = SKShapeNode()
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 28, y: -12))
        tailPath.addQuadCurve(
            to: CGPoint(x: 48, y: 25),
            control: CGPoint(x: 65, y: -2)
        )
        tail.path = tailPath
        tail.strokeColor = body.fillColor
        tail.lineWidth = 7
        tail.fillColor = .clear
        monkey.addChild(tail)

        let hp = wave >= 5 ? 2 : 1
        monkey.userData = NSMutableDictionary()
        monkey.userData?["hp"] = hp
        monkey.userData?["speed"] = CGFloat(65 + wave * 7)

        monkey.position = CGPoint(
            x: size.width / 2 + CGFloat.random(in: -75...75),
            y: size.height * 0.72
        )
        monkey.setScale(0.45)
        monkey.zPosition = 20

        addChild(monkey)
        monkeys.append(monkey)
    }

    // MARK: - Throwing

    private func throwBanana(burst: Bool = false) {
        guard gameState == .playing else { return }

        let banana = SKShapeNode(
            ellipseOf: CGSize(width: burst ? 28 : 20, height: burst ? 12 : 9)
        )
        banana.fillColor = bananaYellow
        banana.strokeColor = .orange
        banana.position = CGPoint(x: size.width / 2, y: 145)
        banana.zRotation = 0.3
        banana.zPosition = 70

        addChild(banana)
        bananas.append(banana)

        let target = crosshair.position
        let travelPoint = CGPoint(
            x: target.x,
            y: min(target.y, size.height * 0.8)
        )

        let move = SKAction.move(to: travelPoint, duration: 0.22)
        let finish = SKAction.run { [weak self, weak banana] in
            guard let self = self, let banana = banana else { return }
            self.hitMonkeys(at: travelPoint, burst: burst)
            banana.removeFromParent()
            self.bananas.removeAll { $0 === banana }
        }

        banana.run(SKAction.sequence([move, finish]))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func hitMonkeys(at point: CGPoint, burst: Bool) {
        let radius: CGFloat = burst ? 125 : 55
        var hitSomething = false

        for monkey in monkeys.reversed() {
            let distance = hypot(
                monkey.position.x - point.x,
                monkey.position.y - point.y
            )

            guard distance < radius else { continue }

            hitSomething = true

            var hp = monkey.userData?["hp"] as? Int ?? 1
            hp -= 1
            monkey.userData?["hp"] = hp

            if hp <= 0 {
                monkey.removeFromParent()
                monkeys.removeAll { $0 === monkey }

                combo += 1
                score += 10 * min(combo, 5)
                coins += 2

                comboLabel.text = combo >= 2 ? "\(combo) COMBO!" : ""
                comboLabel.run(
                    SKAction.sequence([
                        SKAction.scale(to: 1.3, duration: 0.1),
                        SKAction.scale(to: 1.0, duration: 0.1)
                    ])
                )
            } else {
                monkey.run(
                    SKAction.sequence([
                        SKAction.scale(to: 0.6, duration: 0.08),
                        SKAction.scale(to: 0.45, duration: 0.08)
                    ])
                )
            }

            if !burst { break }
        }

        if !hitSomething {
            combo = 0
            comboLabel.text = ""
        }

        updateHUD()
    }

    // MARK: - HUD

    private func updateHUD() {
        scoreLabel?.text = "SCORE: \(score)"
        waveLabel?.text = "WAVE \(wave)"
        coinLabel?.text = "COINS: \(coins)"

        let hearts = String(repeating: "♥ ", count: max(0, health))
        healthLabel?.text = hearts.isEmpty ? "0 ♥" : hearts
    }

    // MARK: - Pause / Game Over

    private func showPause() {
        guard gameState == .playing else { return }
        gameState = .paused

        let overlay = SKShapeNode(
            rectOf: CGSize(width: size.width, height: size.height)
        )
        overlay.name = "pauseOverlay"
        overlay.fillColor = UIColor.black.withAlphaComponent(0.75)
        overlay.strokeColor = .clear
        overlay.zPosition = 200
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(overlay)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "PAUSED"
        title.fontSize = 42
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        title.name = "resumeButton"
        title.zPosition = 201
        addChild(title)

        addButton(
            "RESUME",
            name: "resumeButton",
            position: CGPoint(x: size.width / 2, y: size.height * 0.4),
            size: CGSize(width: 180, height: 60)
        )
    }

    private func endGame() {
        gameState = .gameOver

        bestScore = max(bestScore, score)
        UserDefaults.standard.set(bestScore, forKey: "bananaBlastBest")

        let overlay = SKShapeNode(
            rectOf: CGSize(width: size.width, height: size.height)
        )
        overlay.fillColor = UIColor.black.withAlphaComponent(0.82)
        overlay.strokeColor = .clear
        overlay.zPosition = 200
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(overlay)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "GAME OVER"
        title.fontSize = 42
        title.fontColor = .systemRed
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        title.zPosition = 201
        addChild(title)

        let result = SKLabelNode(fontNamed: "AvenirNext-Bold")
        result.text = "SCORE: \(score)   BEST: \(bestScore)"
        result.fontSize = 20
        result.fontColor = .white
        result.position = CGPoint(x: size.width / 2, y: size.height * 0.53)
        result.zPosition = 201
        addChild(result)

        addButton(
            "PLAY AGAIN",
            name: "replayButton",
            position: CGPoint(x: size.width / 2, y: size.height * 0.36),
            size: CGSize(width: 210, height: 60)
        )
    }

    // MARK: - Touches

    private func buttonName(at point: CGPoint) -> String? {
        for node in nodes(at: point) {
            var current: SKNode? = node

            while let item = current {
                if let name = item.name {
                    return name
                }
                current = item.parent
            }
        }

        return nil
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        switch buttonName(at: point) {
        case "playButton", "replayButton":
            startGame()

        case "throwButton":
            throwBanana()

        case "burstButton":
            throwBanana(burst: true)

        case "pauseButton":
            showPause()

        case "resumeButton":
            if gameState == .paused {
                childNode(withName: "pauseOverlay")?.removeFromParent()
                children
                    .filter { $0.zPosition >= 200 }
                    .forEach { $0.removeFromParent() }
                gameState = .playing
            }

        default:
            if gameState == .playing {
                aimPoint = point
                crosshair.position = point
                throwBanana()
            }
        }
    }

    override func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard gameState == .playing,
              let touch = touches.first else { return }

        let point = touch.location(in: self)

        if point.y > 120 && point.y < size.height - 90 {
            crosshair.position = point
        }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }

        if lastUpdate == 0 {
            lastUpdate = currentTime
        }

        let delta = min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime

        spawnTimer += delta

        if spawnTimer >= spawnInterval {
            spawnTimer = 0
            spawnMonkey()
        }

        for monkey in monkeys {
            let speed = monkey.userData?["speed"] as? CGFloat ?? 70
            monkey.position.y -= speed * CGFloat(delta)

            let progress = max(
                0.0,
                min(1.0, 1.0 - monkey.position.y / size.height)
            )
            monkey.setScale(0.45 + progress * 0.65)

            if monkey.position.y < 125 {
                monkey.removeFromParent()
                monkeys.removeAll { $0 === monkey }

                health -= 1
                combo = 0
                comboLabel.text = ""
                updateHUD()

                if health <= 0 {
                    endGame()
                    return
                }
            }
        }

        let newWave = score / 100 + 1

        if newWave > wave {
            wave = newWave
            spawnInterval = max(0.65, 2.0 - Double(wave) * 0.12)
            updateHUD()
        }
    }
}
