import SpriteKit
import UIKit
import AudioToolbox

final class GameScene: SKScene {
    private enum State { case menu, playing, paused, gameOver }
    private var state: State = .menu

    private let defaults = UserDefaults.standard
    private var score = 0
    private var coins = 0
    private var bestScore = 0
    private var wave = 1
    private var health = 3
    private var specialAmmo = 3
    private var combo = 0
    private var comboTimer: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var spawnClock: TimeInterval = 0
    private var damageFlash: SKShapeNode?
    private var aimPoint = CGPoint.zero
    private var isAiming = false
    private var isThrowing = false
    private var lastUpdate: TimeInterval = 0
    private var enemies: [SKNode] = []
    private var projectiles: [SKNode] = []
    private var particles: [SKNode] = []
    private var hudNodes: [SKNode] = []
    private var worldNodes: [SKNode] = []
    private var playerHand: SKNode?
    private var heldBanana: SKNode?
    private var crosshair: SKNode?
    private var statusLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?
    private var waveLabel: SKLabelNode?
    private var healthLabel: SKLabelNode?
    private var specialLabel: SKLabelNode?
    private var comboLabel: SKLabelNode?
    private var soundOn = true

    private var w: CGFloat { size.width }
    private var h: CGFloat { size.height }
    private var center: CGPoint { CGPoint(x: w * 0.5, y: h * 0.5) }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = false
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        bestScore = defaults.integer(forKey: "bestScore")
        coins = defaults.integer(forKey: "coins")
        buildMenu()
    }

    // MARK: - Scene and visual world

    private func clearScene() {
        removeAllChildren()
        enemies.removeAll()
        projectiles.removeAll()
        particles.removeAll()
        hudNodes.removeAll()
        worldNodes.removeAll()
        playerHand = nil
        heldBanana = nil
        crosshair = nil
    }

    private func addWorld(_ node: SKNode) {
        worldNodes.append(node)
        addChild(node)
    }

    private func addHUD(_ node: SKNode) {
        hudNodes.append(node)
        addChild(node)
    }

    private func makeLabel(_ text: String, size: CGFloat, color: UIColor = .white,
                           align: SKLabelHorizontalAlignmentMode = .center) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = align
        label.verticalAlignmentMode = .center
        return label
    }

    private func roundedPanel(_ size: CGSize, fill: UIColor, stroke: UIColor = .white) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: 14)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = 3
        return node
    }

    private func buildJungle() {
        let sky = SKSpriteNode(color: UIColor(red: 0.35, green: 0.63, blue: 0.48, alpha: 1),
                               size: size)
        sky.position = center
        sky.zPosition = -50
        addWorld(sky)

        // distant bright opening in the canopy
        let glow = SKShapeNode(ellipseOf: CGSize(width: w * 0.38, height: h * 0.66))
        glow.fillColor = UIColor(red: 0.77, green: 0.79, blue: 0.43, alpha: 0.32)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: w * 0.5, y: h * 0.69)
        glow.zPosition = -45
        addWorld(glow)

        // layered blocky jungle foliage
        for layer in 0..<3 {
            for i in 0..<15 {
                let side = i < 8 ? CGFloat(i) : CGFloat(i - 7)
                let x = i < 8 ? side * (w * 0.075) - 8 : w - side * (w * 0.075) + 8
                let y = h * (0.54 + CGFloat((i * 7 + layer * 3) % 5) * 0.085)
                let radius = CGFloat(32 + ((i * 13 + layer * 11) % 34))
                let leaf = SKShapeNode(rectOf: CGSize(width: radius * 1.6, height: radius * 1.15),
                                       cornerRadius: 9)
                let greens: [UIColor] = [
                    UIColor(red: 0.07, green: 0.31, blue: 0.18, alpha: 1),
                    UIColor(red: 0.11, green: 0.42, blue: 0.21, alpha: 1),
                    UIColor(red: 0.20, green: 0.51, blue: 0.24, alpha: 1)
                ]
                leaf.fillColor = greens[(i + layer) % greens.count]
                leaf.strokeColor = .clear
                leaf.zPosition = -35 + CGFloat(layer)
                leaf.position = CGPoint(x: x, y: y)
                addWorld(leaf)
            }
        }

        // tree trunks at edges
        for x in [CGFloat(24), w - 24] {
            let trunk = SKShapeNode(rectOf: CGSize(width: 54, height: h * 0.78), cornerRadius: 8)
            trunk.fillColor = UIColor(red: 0.28, green: 0.17, blue: 0.10, alpha: 1)
            trunk.strokeColor = .clear
            trunk.position = CGPoint(x: x, y: h * 0.39)
            trunk.zPosition = -24
            addWorld(trunk)
        }

        // ground and perspective path
        let ground = SKShapeNode(rectOf: CGSize(width: w, height: h * 0.36))
        ground.fillColor = UIColor(red: 0.24, green: 0.35, blue: 0.16, alpha: 1)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: w * 0.5, y: h * 0.13)
        ground.zPosition = -20
        addWorld(ground)

        let path = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: CGPoint(x: w * 0.18, y: h * 0.02))
        p.addLine(to: CGPoint(x: w * 0.82, y: h * 0.02))
        p.addLine(to: CGPoint(x: w * 0.57, y: h * 0.68))
        p.addLine(to: CGPoint(x: w * 0.43, y: h * 0.68))
        p.closeSubpath()
        path.path = p
        path.fillColor = UIColor(red: 0.55, green: 0.39, blue: 0.22, alpha: 1)
        path.strokeColor = UIColor(red: 0.34, green: 0.25, blue: 0.15, alpha: 1)
        path.lineWidth = 3
        path.zPosition = -18
        addWorld(path)

        // path stones
        for i in 0..<8 {
            let t = CGFloat(i) / 8
            let stone = SKShapeNode(ellipseOf: CGSize(width: 12 + t * 27, height: 5 + t * 9))
            stone.fillColor = UIColor(red: 0.68, green: 0.57, blue: 0.38, alpha: 0.65)
            stone.strokeColor = .clear
            stone.position = CGPoint(x: w * (0.5 + CGFloat((i % 2 == 0 ? -1 : 1)) * (0.02 + t * 0.12)),
                                     y: h * (0.13 + t * 0.20))
            stone.zPosition = -16
            addWorld(stone)
        }

        // foreground grass tufts
        for i in 0..<28 {
            let x = CGFloat(i) / 27 * w
            let tuft = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: -8, y: CGFloat(12 + i % 17)))
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 7, y: CGFloat(8 + i % 13)))
            tuft.path = path
            tuft.strokeColor = UIColor(red: 0.13, green: 0.40, blue: 0.16, alpha: 1)
            tuft.lineWidth = 4
            tuft.position = CGPoint(x: x, y: h * 0.04)
            tuft.zPosition = -10
            addWorld(tuft)
        }
    }

    private func makeBanana(scale: CGFloat = 1) -> SKNode {
        let root = SKNode()
        let curve = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -22, y: -11))
        path.addQuadCurve(to: CGPoint(x: 23, y: 11), control: CGPoint(x: 3, y: -25))
        path.addQuadCurve(to: CGPoint(x: -22, y: -11), control: CGPoint(x: 2, y: 1))
        curve.path = path
        curve.fillColor = UIColor(red: 1, green: 0.83, blue: 0.08, alpha: 1)
        curve.strokeColor = UIColor(red: 0.55, green: 0.34, blue: 0.02, alpha: 1)
        curve.lineWidth = 4
        root.addChild(curve)
        let tip = SKShapeNode(rectOf: CGSize(width: 6, height: 7), cornerRadius: 2)
        tip.fillColor = UIColor(red: 0.35, green: 0.22, blue: 0.08, alpha: 1)
        tip.strokeColor = .clear
        tip.position = CGPoint(x: 22, y: 10)
        root.addChild(tip)
        root.setScale(scale)
        return root
    }

    private func buildHands() {
        let hands = SKNode()
        hands.position = CGPoint(x: w * 0.76, y: h * 0.12)
        hands.zPosition = 30
        let sleeve = SKShapeNode(rectOf: CGSize(width: 178, height: 74), cornerRadius: 22)
        sleeve.fillColor = UIColor(red: 0.17, green: 0.30, blue: 0.16, alpha: 1)
        sleeve.strokeColor = UIColor(red: 0.08, green: 0.16, blue: 0.09, alpha: 1)
        sleeve.lineWidth = 5
        hands.addChild(sleeve)
        let palm = SKShapeNode(ellipseOf: CGSize(width: 130, height: 58))
        palm.fillColor = UIColor(red: 0.72, green: 0.43, blue: 0.25, alpha: 1)
        palm.strokeColor = UIColor(red: 0.38, green: 0.20, blue: 0.12, alpha: 1)
        palm.lineWidth = 4
        palm.position = CGPoint(x: -4, y: 22)
        hands.addChild(palm)
        for i in 0..<4 {
            let finger = SKShapeNode(rectOf: CGSize(width: 18, height: 42), cornerRadius: 8)
            finger.fillColor = UIColor(red: 0.79, green: 0.52, blue: 0.32, alpha: 1)
            finger.strokeColor = UIColor(red: 0.38, green: 0.20, blue: 0.12, alpha: 1)
            finger.lineWidth = 2
            finger.position = CGPoint(x: CGFloat(i) * 20 - 33, y: 39)
            hands.addChild(finger)
        }
        addWorld(hands)
        playerHand = hands
        let held = makeBanana(scale: 1.65)
        held.position = CGPoint(x: -10, y: 64)
        held.zRotation = -0.25
        hands.addChild(held)
        heldBanana = held
    }

    // MARK: - Menus

    private func buildMenu() {
        state = .menu
        clearScene()
        buildJungle()
        buildHands()

        let shade = SKShapeNode(rectOf: CGSize(width: w * 0.62, height: h * 0.67), cornerRadius: 22)
        shade.fillColor = UIColor(white: 0.03, alpha: 0.77)
        shade.strokeColor = UIColor(red: 1, green: 0.82, blue: 0.12, alpha: 1)
        shade.lineWidth = 4
        shade.position = CGPoint(x: w * 0.5, y: h * 0.56)
        shade.zPosition = 60
        addHUD(shade)

        let title = makeLabel("BANANA BLAST", size: 42, color: .yellow)
        title.position = CGPoint(x: w * 0.5, y: h * 0.75)
        title.zPosition = 61
        addHUD(title)

        let subtitle = makeLabel("AIM • THROW • GO BANANAS", size: 15, color: .white)
        subtitle.position = CGPoint(x: w * 0.5, y: h * 0.66)
        subtitle.zPosition = 61
        addHUD(subtitle)

        let start = makeButton("PLAY", name: "play", size: CGSize(width: 190, height: 58),
                               color: UIColor(red: 0.95, green: 0.48, blue: 0.08, alpha: 1))
        start.position = CGPoint(x: w * 0.5, y: h * 0.51)
        start.zPosition = 62
        addHUD(start)

        let how = makeLabel("DRAG TO AIM  •  TAP THROW  •  STOP THE MONKEYS", size: 12, color: .white)
        how.position = CGPoint(x: w * 0.5, y: h * 0.40)
        how.zPosition = 61
        addHUD(how)

        let best = makeLabel("BEST  \(bestScore)     COINS  \(coins)", size: 14, color: .yellow)
        best.position = CGPoint(x: w * 0.5, y: h * 0.31)
        best.zPosition = 61
        addHUD(best)

        let sound = makeButton(soundOn ? "SOUND ON" : "SOUND OFF", name: "sound",
                               size: CGSize(width: 130, height: 42), color: .darkGray)
        sound.position = CGPoint(x: w * 0.86, y: h * 0.90)
        sound.zPosition = 62
        addHUD(sound)
    }

    private func makeButton(_ title: String, name: String, size: CGSize, color: UIColor) -> SKNode {
        let node = roundedPanel(size, fill: color, stroke: UIColor(white: 1, alpha: 0.9))
        node.name = name
        let label = makeLabel(title, size: max(12, size.height * 0.28), color: .white)
        label.name = name
        node.addChild(label)
        return node
    }

    // MARK: - Game start and HUD

    private func startGame() {
        score = 0
        wave = 1
        health = 3
        specialAmmo = 3
        combo = 0
        comboTimer = 0
        elapsed = 0
        spawnClock = 0
        lastUpdate = 0
        isThrowing = false
        state = .playing
        clearScene()
        buildJungle()
        buildHands()
        buildGameHUD()
        spawnMonkey()
    }

    private func buildGameHUD() {
        let top = SKShapeNode(rectOf: CGSize(width: w, height: 58))
        top.fillColor = UIColor(white: 0.02, alpha: 0.58)
        top.strokeColor = .clear
        top.position = CGPoint(x: w * 0.5, y: h - 29)
        top.zPosition = 40
        addHUD(top)

        scoreLabel = makeLabel("SCORE 0", size: 17, color: .white, align: .left)
        scoreLabel?.position = CGPoint(x: 24, y: h - 29)
        scoreLabel?.zPosition = 42
        if let node = scoreLabel { addHUD(node) }

        waveLabel = makeLabel("WAVE 1", size: 16, color: .yellow)
        waveLabel?.position = CGPoint(x: w * 0.5, y: h - 29)
        waveLabel?.zPosition = 42
        if let node = waveLabel { addHUD(node) }

        healthLabel = makeLabel("♥ ♥ ♥", size: 20, color: .systemPink, align: .right)
        healthLabel?.position = CGPoint(x: w - 24, y: h - 29)
        healthLabel?.zPosition = 42
        if let node = healthLabel { addHUD(node) }

        comboLabel = makeLabel("", size: 17, color: .orange)
        comboLabel?.position = CGPoint(x: w * 0.5, y: h * 0.79)
        comboLabel?.zPosition = 42
        if let node = comboLabel { addHUD(node) }

        let throw = makeButton("THROW", name: "throw", size: CGSize(width: 150, height: 62),
                               color: UIColor(red: 0.94, green: 0.42, blue: 0.06, alpha: 1))
        throw.position = CGPoint(x: w - 104, y: 75)
        throw.zPosition = 50
        addHUD(throw)

        let special = makeButton("BURST  \(specialAmmo)", name: "special",
                                 size: CGSize(width: 140, height: 52), color: .systemPurple)
        special.position = CGPoint(x: w - 270, y: 70)
        special.zPosition = 50
        addHUD(special)

        let pause = makeButton("Ⅱ", name: "pause", size: CGSize(width: 48, height: 42),
                               color: UIColor(white: 0.12, alpha: 0.9))
        pause.position = CGPoint(x: w - 35, y: h - 85)
        pause.zPosition = 50
        addHUD(pause)

        let hint = makeLabel("DRAG ANYWHERE TO AIM", size: 11, color: UIColor(white: 1, alpha: 0.75))
        hint.position = CGPoint(x: 24, y: 24)
        hint.horizontalAlignmentMode = .left
        hint.zPosition = 42
        addHUD(hint)

        let dot = SKShapeNode(circleOfRadius: 10)
        dot.fillColor = UIColor(white: 1, alpha: 0.15)
        dot.strokeColor = .white
        dot.lineWidth = 2
        dot.zPosition = 35
        dot.position = CGPoint(x: w * 0.5, y: h * 0.48)
        addHUD(dot)
        let centerDot = SKShapeNode(circleOfRadius: 2.5)
        centerDot.fillColor = .yellow
        centerDot.strokeColor = .clear
        dot.addChild(centerDot)
        crosshair = dot
        aimPoint = dot.position
    }

    private func updateHUD() {
        scoreLabel?.text = "SCORE \(score)"
        waveLabel?.text = "WAVE \(wave)"
        healthLabel?.text = String(repeating: "♥ ", count: max(0, health)).trimmingCharacters(in: .whitespaces)
        if health == 0 { healthLabel?.text = "♡" }
        comboLabel?.text = combo >= 2 ? "\(combo) HIT COMBO!" : ""
        for node in hudNodes where node.name == "special" {
            if let label = node.children.first as? SKLabelNode {
                label.text = "BURST  \(specialAmmo)"
            }
        }
    }

    // MARK: - Enemies

    private func spawnMonkey() {
        guard state == .playing else { return }
        let monkey = SKNode()
        monkey.name = "monkey"
        monkey.userData = NSMutableDictionary()
        monkey.userData?["hp"] = wave >= 5 ? 2 : 1

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 74, height: 18))
        shadow.fillColor = UIColor(white: 0, alpha: 0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -42)
        monkey.addChild(shadow)

        let body = SKShapeNode(ellipseOf: CGSize(width: 48, height: 60))
        body.fillColor = UIColor(red: 0.42, green: 0.23, blue: 0.12, alpha: 1)
        body.strokeColor = UIColor(red: 0.17, green: 0.09, blue: 0.05, alpha: 1)
        body.lineWidth = 4
        body.name = "body"
        monkey.addChild(body)

        for side in [-1, 1] {
            let ear = SKShapeNode(circleOfRadius: 15)
            ear.fillColor = UIColor(red: 0.47, green: 0.27, blue: 0.15, alpha: 1)
            ear.strokeColor = UIColor(red: 0.17, green: 0.09, blue: 0.05, alpha: 1)
            ear.lineWidth = 3
            ear.position = CGPoint(x: CGFloat(side) * 25, y: 13)
            monkey.addChild(ear)
            let inner = SKShapeNode(circleOfRadius: 7)
            inner.fillColor = UIColor(red: 0.86, green: 0.55, blue: 0.43, alpha: 1)
            inner.strokeColor = .clear
            ear.addChild(inner)
        }

        let face = SKShapeNode(ellipseOf: CGSize(width: 39, height: 34))
        face.fillColor = UIColor(red: 0.83, green: 0.61, blue: 0.43, alpha: 1)
        face.strokeColor = UIColor(red: 0.27, green: 0.14, blue: 0.08, alpha: 1)
        face.lineWidth = 2
        face.position = CGPoint(x: 0, y: 8)
        monkey.addChild(face)

        for x in [-8, 8] {
            let eye = SKShapeNode(circleOfRadius: 3.5)
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(x), y: 11)
            face.addChild(eye)
            let shine = SKShapeNode(circleOfRadius: 1)
            shine.fillColor = .white
            shine.strokeColor = .clear
            shine.position = CGPoint(x: 1, y: 1)
            eye.addChild(shine)
        }

        let muzzle = SKShapeNode(ellipseOf: CGSize(width: 20, height: 12))
        muzzle.fillColor = UIColor(red: 0.94, green: 0.77, blue: 0.61, alpha: 1)
        muzzle.strokeColor = .clear
        muzzle.position = CGPoint(x: 0, y: -3)
        face.addChild(muzzle)
        let nose = SKShapeNode(ellipseOf: CGSize(width: 6, height: 4))
        nose.fillColor = .black
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 0, y: 1)
        muzzle.addChild(nose)

        let x = CGFloat.random(in: w * 0.39...w * 0.61)
        monkey.position = CGPoint(x: x, y: h * 0.57)
        monkey.setScale(0.42)
        monkey.zPosition = 5
        addWorld(monkey)
        enemies.append(monkey)

        let duration = max(2.4, 7.2 - Double(wave) * 0.32)
        let move = SKAction.move(to: CGPoint(x: x, y: h * 0.24), duration: duration)
        let scale = SKAction.scale(to: 1.48, duration: duration)
        let bob = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 7, duration: 0.32),
            SKAction.moveBy(x: 0, y: -7, duration: 0.32)
        ]))
        monkey.run(bob, withKey: "bob")
        monkey.run(SKAction.sequence([
            SKAction.group([move, scale]),
            SKAction.run { [weak self, weak monkey] in
                guard let self = self, let monkey = monkey, self.state == .playing else { return }
                self.enemyReachedPlayer(monkey)
            }
        ]), withKey: "approach")
    }

    private func enemyReachedPlayer(_ enemy: SKNode) {
        enemy.removeFromParent()
        enemies.removeAll { $0 === enemy }
        takeDamage()
    }

    private func takeDamage() {
        guard state == .playing else { return }
        health -= 1
        AudioServicesPlaySystemSound(1520)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let flash = SKShapeNode(rectOf: size)
        flash.fillColor = UIColor.red.withAlphaComponent(0.28)
        flash.strokeColor = .clear
        flash.zPosition = 100
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.22),
            SKAction.removeFromParent()
        ]))
        combo = 0
        updateHUD()
        if health <= 0 { endGame() }
    }

    // MARK: - Throwing and hit detection

    private func throwBanana(special: Bool = false) {
        guard state == .playing, !isThrowing else { return }
        if special && specialAmmo <= 0 {
            showFloatingText("NO BURSTS LEFT!", at: CGPoint(x: w * 0.5, y: h * 0.72), color: .orange)
            return
        }
        if special { specialAmmo -= 1 }
        isThrowing = true
        AudioServicesPlaySystemSound(1104)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let projectile = makeBanana(scale: special ? 1.25 : 0.85)
        projectile.position = CGPoint(x: w * 0.75, y: h * 0.25)
        projectile.zPosition = 32
        addChild(projectile)
        projectiles.append(projectile)

        let target = aimPoint
        let duration: TimeInterval = 0.30
        let travel = SKAction.move(to: target, duration: duration)
        let spin = SKAction.rotate(byAngle: .pi * 3, duration: duration)
        let arc = SKAction.moveBy(x: 0, y: 34, duration: duration / 2)
        let fall = SKAction.moveBy(x: 0, y: -34, duration: duration / 2)
        projectile.run(SKAction.sequence([
            SKAction.group([travel, spin, SKAction.sequence([arc, fall])]),
            SKAction.run { [weak self, weak projectile] in
                guard let self = self else { return }
                self.resolveThrow(at: target, special: special)
                projectile?.removeFromParent()
                self.projectiles.removeAll { $0 === projectile }
                self.isThrowing = false
            }
        ]))

        if let banana = heldBanana {
            banana.run(SKAction.sequence([
                SKAction.moveBy(x: 45, y: 35, duration: 0.08),
                SKAction.moveBy(x: -45, y: -35, duration: 0.13)
            ]))
        }
    }

    private func resolveThrow(at point: CGPoint, special: Bool) {
        guard state == .playing else { return }
        let radius: CGFloat = special ? 135 : 78
        let hits = enemies.filter { enemy in
            let distance = hypot(enemy.position.x - point.x, enemy.position.y - point.y)
            return distance < radius
        }
        if hits.isEmpty {
            showFloatingText("MISS!", at: point, color: .white)
        }
        for enemy in hits {
            let hp = (enemy.userData?["hp"] as? Int) ?? 1
            if special || hp <= 1 {
                defeatEnemy(enemy, special: special)
            } else {
                enemy.userData?["hp"] = hp - 1
                enemy.run(SKAction.sequence([
                    SKAction.scale(to: 1.58, duration: 0.07),
                    SKAction.scale(to: 1.48, duration: 0.08)
                ]))
                showFloatingText("OUCH!", at: enemy.position, color: .yellow)
            }
        }
        updateHUD()
    }

    private func defeatEnemy(_ enemy: SKNode, special: Bool) {
        let value = special ? 20 : 10
        combo += 1
        comboTimer = 3.0
        let multiplier = min(5, 1 + combo / 4)
        let earned = value * multiplier
        score += earned
        coins += max(1, earned / 10)
        defaults.set(coins, forKey: "coins")
        showFloatingText("+\(earned)", at: enemy.position, color: .yellow)
        spawnBurst(at: enemy.position)
        AudioServicesPlaySystemSound(1025)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        enemy.removeAllActions()
        enemy.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.05, duration: 0.15),
                SKAction.rotate(byAngle: .pi, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
            ]),
            SKAction.removeFromParent()
        ]))
        enemies.removeAll { $0 === enemy }
        updateHUD()
    }

    private func spawnBurst(at point: CGPoint) {
        for i in 0..<9 {
            let bit = SKShapeNode(rectOf: CGSize(width: 7, height: 7))
            bit.fillColor = [UIColor.yellow, .orange, .green, .white][i % 4]
            bit.strokeColor = .clear
            bit.position = point
            bit.zPosition = 45
            addChild(bit)
            let angle = CGFloat(i) * (.pi * 2 / 9)
            let destination = CGPoint(x: point.x + cos(angle) * 48,
                                      y: point.y + sin(angle) * 48)
            bit.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: destination, duration: 0.28),
                    SKAction.fadeOut(withDuration: 0.28),
                    SKAction.rotate(byAngle: .pi, duration: 0.28)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func showFloatingText(_ text: String, at point: CGPoint, color: UIColor) {
        let label = makeLabel(text, size: 18, color: color)
        label.position = point
        label.zPosition = 80
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 48, duration: 0.65),
                SKAction.fadeOut(withDuration: 0.65)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Pause and game over

    private func showOverlay(title: String, subtitle: String, primary: String, primaryName: String) {
        let overlay = SKShapeNode(rectOf: CGSize(width: w * 0.56, height: h * 0.62), cornerRadius: 22)
        overlay.fillColor = UIColor(white: 0.025, alpha: 0.91)
        overlay.strokeColor = .yellow
        overlay.lineWidth = 4
        overlay.position = center
        overlay.zPosition = 110
        overlay.name = "overlay"
        addChild(overlay)

        let heading = makeLabel(title, size: 34, color: .yellow)
        heading.position = CGPoint(x: 0, y: h * 0.16)
        heading.name = "overlayHeading"
        overlay.addChild(heading)

        let detail = makeLabel(subtitle, size: 16, color: .white)
        detail.position = CGPoint(x: 0, y: h * 0.04)
        overlay.addChild(detail)

        let button = makeButton(primary, name: primaryName, size: CGSize(width: 180, height: 54),
                                color: UIColor(red: 0.91, green: 0.43, blue: 0.06, alpha: 1))
        button.position = CGPoint(x: 0, y: -h * 0.10)
        overlay.addChild(button)

        let menu = makeButton("MAIN MENU", name: "menu", size: CGSize(width: 150, height: 44),
                              color: .darkGray)
        menu.position = CGPoint(x: 0, y: -h * 0.23)
        overlay.addChild(menu)
    }

    private func pauseGame() {
        guard state == .playing else { return }
        state = .paused
        isThrowing = false
        for enemy in enemies { enemy.isPaused = true }
        showOverlay(title: "PAUSED", subtitle: "Take a breather. The monkeys can wait.",
                    primary: "RESUME", primaryName: "resume")
    }

    private func resumeGame() {
        childNode(withName: "overlay")?.removeFromParent()
        for enemy in enemies { enemy.isPaused = false }
        state = .playing
        lastUpdate = 0
    }

    private func endGame() {
        guard state == .playing else { return }
        state = .gameOver
        bestScore = max(bestScore, score)
        defaults.set(bestScore, forKey: "bestScore")
        defaults.set(coins, forKey: "coins")
        let detail = "SCORE \(score)   •   BEST \(bestScore)   •   COINS \(coins)"
        showOverlay(title: "GAME OVER", subtitle: detail,
                    primary: "PLAY AGAIN", primaryName: "replay")
    }

    // MARK: - Touch controls

    private func nodeName(at point: CGPoint) -> String? {
        let hitNodes = nodes(at: point)
        for node in hitNodes {
            var current: SKNode? = node
            while let candidate = current {
                if let name = candidate.name { return name }
                current = candidate.parent
            }
        }
        return nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let name = nodeName(at: point)

        switch state {
        case .menu:
            if name == "sound" {
                soundOn.toggle()
                buildMenu()
            } else if name == "play" || name == nil {
                startGame()
            }
        case .playing:
            if name == "pause" { pauseGame(); return }
            if name == "throw" { throwBanana(); return }
            if name == "special" { throwBanana(special: true); return }
            if point.y > h * 0.15 {
                aimPoint = clampedAim(point)
                isAiming = true
                crosshair?.position = aimPoint
            }
        case .paused:
            if name == "resume" { resumeGame() }
            else if name == "menu" { buildMenu() }
        case .gameOver:
            if name == "replay" { startGame() }
            else if name == "menu" { buildMenu() }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard state == .playing, let touch = touches.first, isAiming else { return }
        let point = clampedAim(touch.location(in: self))
        aimPoint = point
        crosshair?.position = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isAiming = false
    }

    private func clampedAim(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(max(point.x, w * 0.20), w * 0.80),
                y: min(max(point.y, h * 0.24), h * 0.82))
    }

    // MARK: - Difficulty and update loop

    override func update(_ currentTime: TimeInterval) {
        guard state == .playing else {
            lastUpdate = currentTime
            return
        }
        let dt = lastUpdate == 0 ? 0 : min(0.05, currentTime - lastUpdate)
        lastUpdate = currentTime
        elapsed += dt
        spawnClock += dt
        if comboTimer > 0 {
            comboTimer -= dt
            if comboTimer <= 0 {
                combo = 0
                updateHUD()
            }
        }

        let calculatedWave = 1 + Int(score / 100) + Int(elapsed / 45)
        if calculatedWave > wave {
            wave = calculatedWave
            updateHUD()
            showFloatingText("WAVE \(wave)!", at: CGPoint(x: w * 0.5, y: h * 0.72), color: .yellow)
        }

        let spawnInterval = max(0.72, 2.55 - Double(wave - 1) * 0.13)
        if spawnClock >= spawnInterval && enemies.count < min(9, 3 + wave) {
            spawnClock = 0
            spawnMonkey()
        }
    }
}
