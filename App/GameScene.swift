
import SpriteKit
import UIKit
import GameController

final class GameScene: SKScene {

    // MARK: - Game state

    private enum GameState {
        case menu
        case playing
        case paused
        case gameOver
    }

    private final class Enemy {
        var x: CGFloat
        var y: CGFloat
        var hp: Int
        var attackTimer: CGFloat = 0
        let node: SKNode

        init(x: CGFloat, y: CGFloat, node: SKNode) {
            self.x = x
            self.y = y
            self.hp = 2
            self.node = node
        }
    }

    private var gameState: GameState = .menu

    // MARK: - Player

    private var playerX: CGFloat = 2.5
    private var playerY: CGFloat = 2.5
    private var playerAngle: CGFloat = 0

    private let fieldOfView: CGFloat = .pi / 3
    private let mapWidth = 12
    private let mapHeight = 12

    private let gameMap: [[Int]] = [
        [1,1,1,1,1,1,1,1,1,1,1,1],
        [1,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,1,1,0,0,1,1,0,0,0,1],
        [1,0,1,0,0,0,0,1,0,1,0,1],
        [1,0,0,0,1,1,0,0,0,1,0,1],
        [1,0,1,0,0,0,0,1,0,0,0,1],
        [1,0,1,1,1,0,0,1,1,1,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,1],
        [1,0,1,1,0,1,1,1,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,1,0,1],
        [1,0,0,1,1,0,0,0,0,0,0,1],
        [1,1,1,1,1,1,1,1,1,1,1,1]
    ]

    private var enemies: [Enemy] = []

    // MARK: - Statistics

    private var score = 0
    private var health = 100
    private var ammo = 30
    private var wave = 1

    private var bestScore = UserDefaults.standard.integer(
        forKey: "bananaBlastBest"
    )

    // MARK: - Rendering

    private var wallColumns: [SKShapeNode] = []
    private var depthBuffer: [CGFloat] = []

    private var ceilingNode: SKShapeNode!
    private var floorNode: SKShapeNode!

    private var weaponNode: SKNode!
    private var crosshair: SKShapeNode!

    private var scoreLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    private var ammoLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!

    // MARK: - Timing

    private var lastUpdate: TimeInterval = 0
    private var spawnTimer: CGFloat = 0
    private var fireCooldown: CGFloat = 0
    private var damageFlash: CGFloat = 0

    // MARK: - Touch controls

    private var movementTouch: UITouch?
    private var lookTouch: UITouch?

    private var movementOrigin = CGPoint.zero
    private var movementVector = CGPoint.zero
    private var lastLookPoint = CGPoint.zero

    private var isTouchFiring = false

    private var joystickBase: SKShapeNode!
    private var joystickKnob: SKShapeNode!

    // MARK: - Controller

    private var previousFire = false
    private var previousReload = false
    private var previousPause = false
    private var previousSpecial = false

    // MARK: - Colors

    private let bananaYellow = UIColor(
        red: 1.0,
        green: 0.82,
        blue: 0.12,
        alpha: 1
    )

    private let jungleGreen = UIColor(
        red: 0.04,
        green: 0.22,
        blue: 0.10,
        alpha: 1
    )

    // MARK: - Setup

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        backgroundColor = .black

        view.ignoresSiblingOrder = true

        showMenu()
    }

    private func clearScene() {
        removeAllChildren()

        enemies.removeAll()
        wallColumns.removeAll()
        depthBuffer.removeAll()

        movementTouch = nil
        lookTouch = nil

        movementVector = .zero
        isTouchFiring = false
    }

    // MARK: - UI helpers

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
        label.zPosition = 100

        addChild(label)

        return label
    }

    private func addButton(
        _ title: String,
        name: String,
        position: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {

        let button = SKShapeNode(
            rectOf: CGSize(width: width, height: height),
            cornerRadius: 12
        )

        button.name = name
        button.position = position
        button.fillColor = jungleGreen
        button.strokeColor = .white
        button.lineWidth = 2
        button.zPosition = 110

        addChild(button)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")

        label.text = title
        label.fontSize = 17
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name

        button.addChild(label)
    }

    // MARK: - Menu

    private func showMenu() {
        clearScene()

        gameState = .menu
        backgroundColor = jungleGreen

        addLabel(
            "BANANA BLAST",
            size: 44,
            position: CGPoint(
                x: size.width / 2,
                y: size.height * 0.72
            ),
            color: bananaYellow
        )

        addLabel(
            "JUNGLE FIRST-PERSON SHOOTER",
            size: 15,
            position: CGPoint(
                x: size.width / 2,
                y: size.height * 0.62
            )
        )

        addLabel(
            "BEST SCORE: \(bestScore)",
            size: 18,
            position: CGPoint(
                x: size.width / 2,
                y: size.height * 0.49
            )
        )

        addButton(
            "PLAY",
            name: "play",
            position: CGPoint(
                x: size.width / 2,
                y: size.height * 0.34
            ),
            width: 190,
            height: 60
        )

        addLabel(
            "DUALSENSE / DUALSHOCK SUPPORT",
            size: 12,
            position: CGPoint(
                x: size.width / 2,
                y: size.height * 0.17
            ),
            color: .lightGray
        )
    }

    // MARK: - Start game

    private func startGame() {
        clearScene()

        gameState = .playing

        playerX = 2.5
        playerY = 2.5
        playerAngle = 0

        score = 0
        health = 100
        ammo = 30
        wave = 1

        spawnTimer = 0
        fireCooldown = 0
        damageFlash = 0

        lastUpdate = 0

        createWorld()
        createWeapon()
        createCrosshair()
        createHUD()
        createTouchControls()

        spawnEnemy(at: CGPoint(x: 7.5, y: 2.5))
        spawnEnemy(at: CGPoint(x: 8.5, y: 8.5))

        updateHUD()
        renderWorld()
    }

    // MARK: - World rendering

    private func createWorld() {

        let ceilingPath = CGMutablePath()

        ceilingPath.addRect(
            CGRect(
                x: 0,
                y: size.height / 2,
                width: size.width,
                height: size.height / 2
            )
        )

        ceilingNode = SKShapeNode(path: ceilingPath)
        ceilingNode.fillColor = UIColor(
            red: 0.10,
            green: 0.16,
            blue: 0.12,
            alpha: 1
        )
        ceilingNode.strokeColor = .clear
        ceilingNode.zPosition = -20

        addChild(ceilingNode)

        let floorPath = CGMutablePath()

        floorPath.addRect(
            CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: size.height / 2
            )
        )

        floorNode = SKShapeNode(path: floorPath)
        floorNode.fillColor = UIColor(
            red: 0.24,
            green: 0.17,
            blue: 0.10,
            alpha: 1
        )
        floorNode.strokeColor = .clear
        floorNode.zPosition = -19

        addChild(floorNode)

        for _ in 0..<120 {
            let column = SKShapeNode()

            column.strokeColor = .clear
            column.zPosition = 2

            addChild(column)

            wallColumns.append(column)
        }

        depthBuffer = Array(
            repeating: 12,
            count: wallColumns.count
        )
    }

    private func isWall(_ x: CGFloat, _ y: CGFloat) -> Bool {

        let mapX = Int(x)
        let mapY = Int(y)

        if mapX < 0 || mapY < 0 ||
            mapX >= mapWidth || mapY >= mapHeight {
            return true
        }

        return gameMap[mapY][mapX] != 0
    }

    private func renderWorld() {

        guard !wallColumns.isEmpty else { return }

        let count = wallColumns.count
        let columnWidth = size.width / CGFloat(count)

        for index in 0..<count {

            let rayAngle =
                playerAngle -
                fieldOfView / 2 +
                (CGFloat(index) / CGFloat(count)) * fieldOfView

            let rayX = cos(rayAngle)
            let rayY = sin(rayAngle)

            var distance: CGFloat = 0

            while distance < 12 {

                let testX = playerX + rayX * distance
                let testY = playerY + rayY * distance

                if isWall(testX, testY) {
                    break
                }

                distance += 0.025
            }

            distance = max(distance, 0.05)

            let correctedDistance = max(
                distance * cos(rayAngle - playerAngle),
                0.1
            )

            depthBuffer[index] = correctedDistance

            let wallHeight = min(
                size.height * 2,
                size.height / correctedDistance
            )

            let rect = CGRect(
                x: CGFloat(index) * columnWidth,
                y: (size.height - wallHeight) / 2,
                width: columnWidth + 1,
                height: wallHeight
            )

            let path = CGMutablePath()
            path.addRect(rect)

            let shade = max(
                0.15,
                1.0 - correctedDistance / 10
            )

            let stripe = index % 8 < 2 ? 0.8 : 1.0

            wallColumns[index].path = path

            wallColumns[index].fillColor = UIColor(
                red: 0.13 * shade * stripe,
                green: 0.42 * shade * stripe,
                blue: 0.17 * shade * stripe,
                alpha: 1
            )
        }

        renderEnemies()
    }

    // MARK: - Monkey enemies

    private func createMonkey() -> SKNode {

        let monkey = SKNode()

        let body = SKShapeNode(
            ellipseOf: CGSize(width: 65, height: 78)
        )

        body.fillColor = UIColor(
            red: 0.38,
            green: 0.20,
            blue: 0.10,
            alpha: 1
        )

        body.strokeColor = .black
        body.lineWidth = 2

        monkey.addChild(body)

        let face = SKShapeNode(
            ellipseOf: CGSize(width: 43, height: 43)
        )

        face.fillColor = UIColor(
            red: 0.85,
            green: 0.63,
            blue: 0.42,
            alpha: 1
        )

        face.strokeColor = .clear
        face.position = CGPoint(x: 0, y: 13)

        monkey.addChild(face)

        for x in [-9.0, 9.0] {

            let eye = SKShapeNode(circleOfRadius: 3)

            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.position = CGPoint(x: x, y: 17)

            face.addChild(eye)
        }

        let mouth = SKShapeNode(
            ellipseOf: CGSize(width: 15, height: 5)
        )

        mouth.fillColor = .black
        mouth.strokeColor = .clear
        mouth.position = CGPoint(x: 0, y: 2)

        face.addChild(mouth)

        let earLeft = SKShapeNode(circleOfRadius: 9)
        earLeft.fillColor = body.fillColor
        earLeft.strokeColor = .clear
        earLeft.position = CGPoint(x: -25, y: 27)

        monkey.addChild(earLeft)

        let earRight = SKShapeNode(circleOfRadius: 9)
        earRight.fillColor = body.fillColor
        earRight.strokeColor = .clear
        earRight.position = CGPoint(x: 25, y: 27)

        monkey.addChild(earRight)

        return monkey
    }

    private func spawnEnemy(at position: CGPoint) {

        let monkey = createMonkey()

        monkey.zPosition = 20

        addChild(monkey)

        let enemy = Enemy(
            x: position.x,
            y: position.y,
            node: monkey
        )

        enemy.hp = wave >= 4 ? 3 : 2

        enemies.append(enemy)
    }

    private func spawnRandomEnemy() {

        for _ in 0..<40 {

            let x = CGFloat(Int.random(in: 1...10)) + 0.5
            let y = CGFloat(Int.random(in: 1...10)) + 0.5

            if isWall(x, y) {
                continue
            }

            let distance = hypot(
                x - playerX,
                y - playerY
            )

            if distance > 4 {
                spawnEnemy(
                    at: CGPoint(x: x, y: y)
                )
                return
            }
        }
    }

    private func renderEnemies() {

        let columnWidth = size.width / CGFloat(wallColumns.count)

        for enemy in enemies {

            let dx = enemy.x - playerX
            let dy = enemy.y - playerY

            let distance = hypot(dx, dy)

            var angle = atan2(dy, dx) - playerAngle

            while angle > .pi {
                angle -= .pi * 2
            }

            while angle < -.pi {
                angle += .pi * 2
            }

            guard abs(angle) < fieldOfView / 2 else {
                enemy.node.isHidden = true
                continue
            }

            let screenX =
                (angle / fieldOfView + 0.5) * size.width

            let column = min(
                wallColumns.count - 1,
                max(0, Int(screenX / columnWidth))
            )

            if distance > depthBuffer[column] + 0.1 {
                enemy.node.isHidden = true
                continue
            }

            enemy.node.isHidden = false

            let scale = min(
                2.0,
                max(0.08, 1.0 / distance)
            )

            enemy.node.position = CGPoint(
                x: screenX,
                y: size.height / 2
            )

            enemy.node.setScale(scale)
        }
    }

    // MARK: - Banana weapon

    private func createWeapon() {

        weaponNode = SKNode()

        weaponNode.position = CGPoint(
            x: size.width / 2,
            y: 90
        )

        weaponNode.zPosition = 50

        addChild(weaponNode)

        let launcher = SKShapeNode(
            rectOf: CGSize(width: 105, height: 85),
            cornerRadius: 16
        )

        launcher.fillColor = UIColor(
            red: 0.35,
            green: 0.20,
            blue: 0.10,
            alpha: 1
        )

        launcher.strokeColor = .black
        launcher.lineWidth = 3

        weaponNode.addChild(launcher)

        let banana = SKShapeNode(
            ellipseOf: CGSize(width: 100, height: 27)
        )

        banana.fillColor = bananaYellow
        banana.strokeColor = UIColor(
            red: 0.72,
            green: 0.48,
            blue: 0.04,
            alpha: 1
        )

        banana.lineWidth = 3
        banana.position = CGPoint(x: 0, y: 50)
        banana.zRotation = 0.2

        weaponNode.addChild(banana)

        let grip = SKShapeNode(
            rectOf: CGSize(width: 35, height: 48),
            cornerRadius: 8
        )

        grip.fillColor = UIColor.darkGray
        grip.strokeColor = .black
        grip.position = CGPoint(x: 0, y: -60)

        weaponNode.addChild(grip)
    }

    private func animateWeapon() {

        weaponNode.removeAction(forKey: "fire")

        let recoil = SKAction.moveBy(
            x: 0,
            y: -18,
            duration: 0.06
        )

        let returnAction = SKAction.moveBy(
            x: 0,
            y: 18,
            duration: 0.12
        )

        weaponNode.run(
            SKAction.sequence([
                recoil,
                returnAction
            ]),
            withKey: "fire"
        )
    }

    // MARK: - Crosshair

    private func createCrosshair() {

        crosshair = SKShapeNode(circleOfRadius: 9)

        crosshair.strokeColor = .white
        crosshair.fillColor = .clear
        crosshair.lineWidth = 2

        crosshair.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )

        crosshair.zPosition = 80

        addChild(crosshair)

        let horizontal = SKShapeNode(
            rectOf: CGSize(width: 25, height: 2)
        )

        horizontal.fillColor = .white
        horizontal.strokeColor = .clear

        crosshair.addChild(horizontal)

        let vertical = SKShapeNode(
            rectOf: CGSize(width: 2, height: 25)
        )

        vertical.fillColor = .white
        vertical.strokeColor = .clear

        crosshair.addChild(vertical)
    }

    // MARK: - HUD

    private func createHUD() {

        scoreLabel = addLabel(
            "SCORE: 0",
            size: 17,
            position: CGPoint(x: 95, y: size.height - 30)
        )

        healthLabel = addLabel(
            "HEALTH: 100",
            size: 17,
            position: CGPoint(x: 105, y: size.height - 58),
            color: .systemGreen
        )

        waveLabel = addLabel(
            "WAVE 1",
            size: 18,
            position: CGPoint(
                x: size.width / 2,
                y: size.height - 30
            ),
            color: bananaYellow
        )

        ammoLabel = addLabel(
            "AMMO: 30",
            size: 18,
            position: CGPoint(
                x: size.width - 100,
                y: size.height - 30
            ),
            color: bananaYellow
        )
    }

    private func updateHUD() {

        scoreLabel?.text = "SCORE: \(score)"
        healthLabel?.text = "HEALTH: \(health)"
        ammoLabel?.text = "AMMO: \(ammo)"
        waveLabel?.text = "WAVE \(wave)"
    }

    // MARK: - Touch controls

    private func createTouchControls() {

        joystickBase = SKShapeNode(circleOfRadius: 58)

        joystickBase.position = CGPoint(
            x: 85,
            y: 95
        )

        joystickBase.fillColor = UIColor.white.withAlphaComponent(0.12)
        joystickBase.strokeColor = UIColor.white.withAlphaComponent(0.6)
        joystickBase.lineWidth = 2
        joystickBase.zPosition = 90

        addChild(joystickBase)

        joystickKnob = SKShapeNode(circleOfRadius: 25)

        joystickKnob.fillColor = UIColor.white.withAlphaComponent(0.35)
        joystickKnob.strokeColor = .white
        joystickKnob.lineWidth = 2
        joystickKnob.zPosition = 91

        joystickBase.addChild(joystickKnob)

        addButton(
            "FIRE",
            name: "fire",
            position: CGPoint(
                x: size.width - 85,
                y: 95
            ),
            width: 105,
            height: 60
        )

        addButton(
            "RELOAD",
            name: "reload",
            position: CGPoint(
                x: size.width - 205,
                y: 95
            ),
            width: 100,
            height: 48
        )

        addButton(
            "Ⅱ",
            name: "pause",
            position: CGPoint(
                x: size.width - 40,
                y: size.height - 75
            ),
            width: 48,
            height: 42
        )

        addLabel(
            "MOVE",
            size: 11,
            position: CGPoint(x: 85, y: 22),
            color: .lightGray
        )

        addLabel(
            "DRAG RIGHT SIDE TO TURN",
            size: 11,
            position: CGPoint(
                x: size.width * 0.62,
                y: 25
            ),
            color: .lightGray
        )
    }

    // MARK: - Movement and collision

    private func movePlayer(forward: CGFloat, sideways: CGFloat) {

        let speed: CGFloat = 3.0

        let dx =
            cos(playerAngle) * forward * speed +
            cos(playerAngle + .pi / 2) * sideways * speed

        let dy =
            sin(playerAngle) * forward * speed +
            sin(playerAngle + .pi / 2) * sideways * speed

        let nextX = playerX + dx
        let nextY = playerY + dy

        if !isWall(nextX, playerY) {
            playerX = nextX
        }

        if !isWall(playerX, nextY) {
            playerY = nextY
        }
    }

    // MARK: - Shooting

    private func shootBanana(special: Bool = false) {

        guard gameState == .playing else { return }
        guard fireCooldown <= 0 else { return }

        guard ammo > 0 else {
            reload()
            return
        }

        ammo -= 1

        fireCooldown = special ? 0.45 : 0.22

        animateWeapon()

        let targetAngle = playerAngle

        var bestEnemy: Enemy?
        var bestDistance: CGFloat = 999

        for enemy in enemies {

            let dx = enemy.x - playerX
            let dy = enemy.y - playerY

            let distance = hypot(dx, dy)

            var angle = atan2(dy, dx) - targetAngle

            while angle > .pi {
                angle -= .pi * 2
            }

            while angle < -.pi {
                angle += .pi * 2
            }

            let aimTolerance: CGFloat = special ? 0.24 : 0.13

            if abs(angle) < aimTolerance && distance < bestDistance {

                bestDistance = distance
                bestEnemy = enemy
            }
        }

        if let enemy = bestEnemy {

            enemy.hp -= special ? 2 : 1

            enemy.node.run(
                SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: 0.05),
                    SKAction.scale(to: 1.0, duration: 0.08)
                ])
            )

            if enemy.hp <= 0 {

                enemy.node.removeFromParent()
                enemies.removeAll { $0 === enemy }

                score += 25

                updateHUD()
            }
        }

        updateHUD()

        UIImpactFeedbackGenerator(
            style: .medium
        ).impactOccurred()
    }

    private func reload() {

        guard ammo < 30 else { return }

        ammo = 30

        weaponNode.run(
            SKAction.sequence([
                SKAction.rotate(byAngle: 0.12, duration: 0.12),
                SKAction.rotate(byAngle: -0.12, duration: 0.12)
            ])
        )

        updateHUD()
    }

    // MARK: - Controller support

    private func updateController(delta: CGFloat) {

        guard let controller = GCController.controllers().first,
              let pad = controller.extendedGamepad else {
            return
        }

        let leftX = CGFloat(pad.leftThumbstick.xAxis.value)
        let leftY = CGFloat(pad.leftThumbstick.yAxis.value)

        let rightX = CGFloat(pad.rightThumbstick.xAxis.value)

        let deadZone: CGFloat = 0.16

        let forward = abs(leftY) > deadZone ? leftY : 0
        let sideways = abs(leftX) > deadZone ? leftX : 0

        movePlayer(
            forward: forward,
            sideways: sideways
        )

        if abs(rightX) > deadZone {

            playerAngle += rightX * delta * 2.8
        }

        let firePressed = pad.rightTrigger.value > 0.35

        if firePressed {
            shootBanana()
        }

        let specialPressed = pad.leftTrigger.value > 0.5

        if specialPressed && !previousSpecial {
            shootBanana(special: true)
        }

        let reloadPressed = pad.buttonX.isPressed

        if reloadPressed && !previousReload {
            reload()
        }

        let pausePressed = pad.buttonMenu.isPressed

        if pausePressed && !previousPause {

            if gameState == .playing {
                showPause()
            } else if gameState == .paused {
                resumeGame()
            }
        }

        previousFire = firePressed
        previousSpecial = specialPressed
        previousReload = reloadPressed
        previousPause = pausePressed
    }

    // MARK: - Pause

    private func showPause() {

        guard gameState == .playing else { return }

        gameState = .paused

        let overlay = SKShapeNode(
            rectOf: CGSize(
                width: size.width,
                height: size.height
            )
        )

        overlay.name = "pauseOverlay"
        overlay.fillColor = UIColor.black.withAlphaComponent(0.8)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        overlay.zPosition = 200

        addChild(overlay)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")

        title.text = "PAUSED"
        title.fontSize = 42
        title.position = CGPoint(
            x: size.width / 2,
            y: size.height * 0.60
        )
        title.zPosition = 201

        addChild(title)

        addButton(
            "RESUME",
            name: "resume",
            position: CGPoint(
                x: size.width / 2,
                y: size.height * 0.40
            ),
            width: 180,
            height: 60
        )
    }

    private func resumeGame() {

        childNode(withName: "pauseOverlay")?.removeFromParent()

        children
            .filter { $0.zPosition >= 200 }
            .forEach { $0.removeFromParent() }

        gameState = .playing
    }

    // MARK: - Game over

    private func endGame() {

        gameState = .gameOver

        bestScore = max(bestScore, score)

        UserDefaults.standard.set(
            bestScore,
            forKey: "bananaBlastBest"
        )

        let overlay = SKShapeNode(
            rectOf: CGSize(
                width: size.width,
                height: size.height
            )
        )

        overlay.fillColor = UIColor.black.withAlphaComponent(0.88)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2
        )
        overlay.zPosition = 200

        addChild(overlay)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")

        title.text = "GAME OVER"
        title.fontSize = 42
        title.fontColor = .systemRed
        title.position = CGPoint(
            x: size.width / 2,
            y: size.height * 0.65
        )
        title.zPosition = 201

        addChild(title)

        let result = SKLabelNode(fontNamed: "AvenirNext-Bold")

        result.text = "SCORE: \(score)   BEST: \(bestScore)"
        result.fontSize = 19
        result.position = CGPoint(
            x: size.width / 2,
            y: size.height * 0.52
        )
        result.zPosition = 201

        addChild(result)

        addButton(
            "PLAY AGAIN",
            name: "replay",
            position: CGPoint(
                x: size.width / 2,
                y: size.height * 0.36
            ),
            width: 210,
            height: 60
        )
    }

    // MARK: - Touch handling

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

        case "play", "replay":
            startGame()
            return

        case "fire":
            isTouchFiring = true
            shootBanana()
            return

        case "reload":
            reload()
            return

        case "pause":
            showPause()
            return

        case "resume":
            resumeGame()
            return

        default:
            break
        }

        guard gameState == .playing else { return }

        if point.x < size.width * 0.35 && movementTouch == nil {

            movementTouch = touch
            movementOrigin = point

            joystickBase.position = point
            joystickKnob.position = .zero

        } else if lookTouch == nil {

            lookTouch = touch
            lastLookPoint = point
        }
    }

    override func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        guard gameState == .playing else { return }

        for touch in touches {

            let point = touch.location(in: self)

            if touch === movementTouch {

                let dx = point.x - movementOrigin.x
                let dy = point.y - movementOrigin.y

                let length = max(
                    1,
                    hypot(dx, dy)
                )

                let limit: CGFloat = 45

                let scale = min(
                    1,
                    limit / length
                )

                let adjustedX = dx * scale
                let adjustedY = dy * scale

                joystickKnob.position = CGPoint(
                    x: adjustedX,
                    y: adjustedY
                )

                movementVector = CGPoint(
                    x: adjustedX / limit,
                    y: adjustedY / limit
                )
            }

            if touch === lookTouch {

                let dx = point.x - lastLookPoint.x

                playerAngle += dx * 0.006

                lastLookPoint = point
            }
        }
    }

    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        for touch in touches {

            if touch === movementTouch {

                movementTouch = nil
                movementVector = .zero

                joystickKnob.position = .zero
            }

            if touch === lookTouch {
                lookTouch = nil
            }
        }

        isTouchFiring = false
    }

    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {

        touchesEnded(touches, with: event)
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {

        guard gameState == .playing else { return }

        if lastUpdate == 0 {
            lastUpdate = currentTime
        }

        let delta = CGFloat(
            min(currentTime - lastUpdate, 0.05)
        )

        lastUpdate = currentTime

        fireCooldown = max(0, fireCooldown - delta)

        if movementTouch != nil {

            movePlayer(
                forward: movementVector.y,
                sideways: movementVector.x
            )
        }

        updateController(delta: delta)

        if isTouchFiring {
            shootBanana()
        }

        updateEnemies(delta: delta)

        spawnTimer += delta

        let spawnInterval = max(
            0.8,
            3.0 - CGFloat(wave) * 0.15
        )

        if spawnTimer >= spawnInterval {

            spawnTimer = 0

            if enemies.count < 8 {
                spawnRandomEnemy()
            }
        }

        if score >= wave * 100 {

            wave += 1

            updateHUD()
        }

        if damageFlash > 0 {
            damageFlash -= delta
        }

        renderWorld()
    }

    // MARK: - Enemy AI

    private func updateEnemies(delta: CGFloat) {

        for enemy in enemies {

            let dx = playerX - enemy.x
            let dy = playerY - enemy.y

            let distance = max(
                0.01,
                hypot(dx, dy)
            )

            enemy.attackTimer -= delta

            if distance > 1.15 {

                let speed: CGFloat = 0.7

                let stepX = (dx / distance) * speed * delta
                let stepY = (dy / distance) * speed * delta

                if !isWall(enemy.x + stepX, enemy.y) {
                    enemy.x += stepX
                }

                if !isWall(enemy.x, enemy.y + stepY) {
                    enemy.y += stepY
                }

            } else if enemy.attackTimer <= 0 {

                health = max(0, health - 8)

                enemy.attackTimer = 1.2

                updateHUD()

                if health <= 0 {
                    endGame()
                    return
                }
            }
        }
    }
}
