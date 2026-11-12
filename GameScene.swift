import SpriteKit
import UIKit

final class GameScene: SKScene {
    private let sky = SKShapeNode()
    private let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let waveLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let messageLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let throwButton = SKShapeNode(rectOf: CGSize(width: 150, height: 64), cornerRadius: 12)
    private let specialButton = SKShapeNode(rectOf: CGSize(width: 112, height: 52), cornerRadius: 10)
    private let aimDot = SKShapeNode(circleOfRadius: 8)
    private var hand: SKShapeNode!
    private var banana: SKShapeNode!
    private var monkeys: [SKNode] = []
    private var score = 0
    private var wave = 1
    private var bananasThrown = 0
    private var lastSpawn: TimeInterval = 0
    private var gameStarted = false
    private var isThrowing = false
    private var aimPoint = CGPoint(x: 700, y: 280)

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.20, green: 0.43, blue: 0.28, alpha: 1)
        buildWorld()
        showTitle()
    }

    private func buildWorld() {
        removeAllChildren()
        monkeys.removeAll()
        let w = size.width, h = size.height

        let skyNode = SKSpriteNode(color: UIColor(red: 0.48, green: 0.72, blue: 0.55, alpha: 1),
                                   size: CGSize(width: w, height: h))
        skyNode.position = CGPoint(x: w/2, y: h/2)
        skyNode.zPosition = -20
        addChild(skyNode)

        // Layered jungle silhouettes and a path leading straight ahead.
        for i in 0..<9 {
            let x = CGFloat(i) * w / 8
            let tree = SKShapeNode(rectOf: CGSize(width: 58, height: h * 0.78))
            tree.fillColor = UIColor(red: 0.10, green: 0.30, blue: 0.19, alpha: 1)
            tree.strokeColor = .clear
            tree.position = CGPoint(x: x, y: h * 0.52)
            tree.zPosition = -10
            addChild(tree)
            for j in 0..<3 {
                let leaf = SKShapeNode(circleOfRadius: 48)
                leaf.fillColor = UIColor(red: 0.08, green: 0.38 + CGFloat(j)*0.035, blue: 0.20, alpha: 1)
                leaf.strokeColor = .clear
                leaf.position = CGPoint(x: x + CGFloat(j-1)*34, y: h*0.82 + CGFloat(j%2)*20)
                leaf.zPosition = -9
                addChild(leaf)
            }
        }

        let ground = SKShapeNode(rectOf: CGSize(width: w, height: h*0.34))
        ground.fillColor = UIColor(red: 0.34, green: 0.25, blue: 0.14, alpha: 1)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: w/2, y: h*0.12)
        ground.zPosition = -5
        addChild(ground)

        let path = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: CGPoint(x: w*0.30, y: h*0.28))
        p.addLine(to: CGPoint(x: w*0.70, y: h*0.28))
        p.addLine(to: CGPoint(x: w*0.57, y: h*0.66))
        p.addLine(to: CGPoint(x: w*0.43, y: h*0.66))
        p.closeSubpath()
        path.path = p
        path.fillColor = UIColor(red: 0.62, green: 0.48, blue: 0.28, alpha: 1)
        path.strokeColor = .clear
        path.zPosition = -4
        addChild(path)

        scoreLabel.fontSize = 25
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 28, y: h-42)
        scoreLabel.zPosition = 30
        addChild(scoreLabel)

        waveLabel.fontSize = 18
        waveLabel.fontColor = .white
        waveLabel.horizontalAlignmentMode = .right
        waveLabel.position = CGPoint(x: w-28, y: h-40)
        waveLabel.zPosition = 30
        addChild(waveLabel)

        aimDot.fillColor = .yellow
        aimDot.strokeColor = .black
        aimDot.lineWidth = 3
        aimDot.zPosition = 25
        addChild(aimDot)

        hand = SKShapeNode(rectOf: CGSize(width: 145, height: 75), cornerRadius: 22)
        hand.fillColor = UIColor(red: 0.78, green: 0.49, blue: 0.28, alpha: 1)
        hand.strokeColor = UIColor(red: 0.35, green: 0.19, blue: 0.10, alpha: 1)
        hand.lineWidth = 5
        hand.position = CGPoint(x: w*0.76, y: h*0.13)
        hand.zPosition = 15
        addChild(hand)

        banana = makeBanana()
        banana.position = CGPoint(x: w*0.72, y: h*0.23)
        banana.zPosition = 16
        addChild(banana)

        configureButton(throwButton, title: "THROW", color: .systemOrange,
                        position: CGPoint(x: w-105, y: 82), z: 40)
        configureButton(specialButton, title: "SPECIAL", color: .systemPurple,
                        position: CGPoint(x: w-275, y: 72), z: 40)
        updateHUD()
    }

    private func configureButton(_ node: SKShapeNode, title: String, color: UIColor,
                                 position: CGPoint, z: CGFloat) {
        node.fillColor = color
        node.strokeColor = .white
        node.lineWidth = 3
        node.position = position
        node.zPosition = z
        addChild(node)
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = title
        label.fontSize = title == "THROW" ? 18 : 12
        label.verticalAlignmentMode = .center
        label.fontColor = .white
        label.name = title.lowercased()
        label.zPosition = 1
        node.addChild(label)
        node.name = title.lowercased()
    }

    private func makeBanana() -> SKShapeNode {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -22, y: -13))
        path.addQuadCurve(to: CGPoint(x: 24, y: 12), control: CGPoint(x: 5, y: -24))
        path.addQuadCurve(to: CGPoint(x: -22, y: -13), control: CGPoint(x: 4, y: 1))
        shape.path = path
        shape.fillColor = .yellow
        shape.strokeColor = UIColor(red: 0.55, green: 0.35, blue: 0.04, alpha: 1)
        shape.lineWidth = 4
        return shape
    }

    private func showTitle() {
        let title = SKLabelNode(fontNamed: "Menlo-Bold")
        title.text = "BANANA BLAST"
        title.fontSize = 44
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width/2, y: size.height*0.68)
        title.zPosition = 50
        title.name = "title"
        addChild(title)

        messageLabel.text = "TAP ANYWHERE TO START"
        messageLabel.fontSize = 18
        messageLabel.fontColor = .white
        messageLabel.position = CGPoint(x: size.width/2, y: size.height*0.54)
        messageLabel.zPosition = 50
        addChild(messageLabel)
    }

    private func updateHUD() {
        scoreLabel.text = "SCORE: \(score)"
        waveLabel.text = "WAVE: \(wave)"
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameStarted else { return }
        let interval = max(0.75, 2.4 - Double(wave) * 0.12)
        if currentTime - lastSpawn > interval {
            spawnMonkey()
            lastSpawn = currentTime
        }
        let nextWave = 1 + score / 100
        if nextWave > wave {
            wave = nextWave
            updateHUD()
        }
    }

    private func spawnMonkey() {
        let monkey = SKNode()
        monkey.name = "monkey"
        let body = SKShapeNode(circleOfRadius: 28)
        body.fillColor = UIColor(red: 0.48, green: 0.27, blue: 0.13, alpha: 1)
        body.strokeColor = .black
        body.lineWidth = 4
        monkey.addChild(body)

        let face = SKShapeNode(ellipseOf: CGSize(width: 36, height: 30))
        face.fillColor = UIColor(red: 0.88, green: 0.67, blue: 0.48, alpha: 1)
        face.strokeColor = .black
        face.lineWidth = 2
        face.position = CGPoint(x: 0, y: -3)
        monkey.addChild(face)

        for x in [-9, 9] {
            let eye = SKShapeNode(circleOfRadius: 3)
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(x), y: 2)
            monkey.addChild(eye)
        }
        let mouth = SKShapeNode(rectOf: CGSize(width: 9, height: 3))
        mouth.fillColor = .black
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 0, y: -12)
        monkey.addChild(mouth)

        let x = CGFloat.random(in: size.width*0.35...size.width*0.65)
        monkey.position = CGPoint(x: x, y: size.height*0.58)
        monkey.setScale(0.45)
        monkey.zPosition = 5
        addChild(monkey)
        monkeys.append(monkey)

        let duration = max(3.0, 8.0 - Double(wave)*0.35)
        let approach = SKAction.group([
            SKAction.move(to: CGPoint(x: x, y: size.height*0.31), duration: duration),
            SKAction.scale(to: 1.45, duration: duration)
        ])
        monkey.run(SKAction.sequence([approach, SKAction.removeFromParent()]))
    }

    private func throwBanana(special: Bool = false) {
        guard gameStarted, !isThrowing else { return }
        isThrowing = true
        let projectile = makeBanana()
        projectile.position = banana.position
        projectile.zPosition = 20
        projectile.setScale(special ? 1.8 : 1.0)
        addChild(projectile)

        let target = aimPoint
        let travel = SKAction.move(to: target, duration: 0.35)
        let spin = SKAction.rotate(byAngle: .pi * 3, duration: 0.35)
        projectile.run(SKAction.sequence([
            SKAction.group([travel, spin]),
            SKAction.run { [weak self, weak projectile] in
                guard let self = self else { return }
                self.checkHits(at: target, special: special)
                projectile?.removeFromParent()
                self.isThrowing = false
            }
        ]))
        bananasThrown += 1
        banana.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: -24, duration: 0.08),
            SKAction.moveBy(x: 0, y: 24, duration: 0.10)
        ]))
    }

    private func checkHits(at point: CGPoint, special: Bool) {
        let hits = monkeys.filter {
            hypot($0.position.x - point.x, $0.position.y - point.y) < (special ? 105 : 65)
        }
        for monkey in hits {
            score += special ? 30 : 10
            let burst = SKLabelNode(fontNamed: "Menlo-Bold")
            burst.text = "+\(special ? 30 : 10)"
            burst.fontSize = 20
            burst.fontColor = .yellow
            burst.position = monkey.position
            burst.zPosition = 35
            addChild(burst)
            burst.run(SKAction.sequence([
                SKAction.group([SKAction.moveBy(x: 0, y: 45, duration: 0.5),
                                SKAction.fadeOut(withDuration: 0.5)]),
                SKAction.removeFromParent()
            ]))
            monkey.removeAllActions()
            monkey.removeFromParent()
            monkeys.removeAll { $0 === monkey }
        }
        updateHUD()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if !gameStarted {
            gameStarted = true
            childNode(withName: "title")?.removeFromParent()
            messageLabel.removeFromParent()
            spawnMonkey()
            return
        }
        if throwButton.contains(point) {
            throwBanana()
        } else if specialButton.contains(point) {
            throwBanana(special: true)
        } else {
            aimPoint = point
            aimDot.position = point
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, gameStarted else { return }
        let point = touch.location(in: self)
        if point.x < size.width - 320 {
            aimPoint = point
            aimDot.position = point
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, gameStarted else { return }
        let point = touch.location(in: self)
        if throwButton.contains(point) { throwBanana() }
        if specialButton.contains(point) { throwBanana(special: true) }
    }
}
