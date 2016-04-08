//
//  GameScene.swift
//  MazeMan
//
//  Created by Paul McDonald  on 3/30/16.
//  Copyright (c) 2016 Paul McDonald . All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let right = SKAction.moveByX(64, y: 0, duration: 0.6)
    let left = SKAction.moveByX(-64, y: 0, duration: 0.6)
    let up = SKAction.moveByX(0, y: 64, duration: 0.6)
    let down = SKAction.moveByX(0, y: -64, duration: 0.6)
    
    let starSound = SKAction.playSoundFileNamed("celebration.wav", waitForCompletion: false)
    let eatSound = SKAction.playSoundFileNamed("bite.wav", waitForCompletion: false)
    let shootSound = SKAction.playSoundFileNamed("gunShot.mp3", waitForCompletion: false)
    let dinoHitSound = SKAction.playSoundFileNamed("deathSound.wav", waitForCompletion: false)
    let punchSound = SKAction.playSoundFileNamed("punch.wav", waitForCompletion: false)
    
    var objectGrid: [[Int]] = []
    var blockCount = 0
    var blockTimer: NSTimer!
    
    var dino1: Dino!
    var dino1Timer: NSTimer!
    
    var dino2: Dino!
    var dino2Timer: NSTimer!
    
    var dino3: Dino!
    var dino3Timer: NSTimer!
    var dino3Direction: Int!
    var dino3PositionTimer: NSTimer!
    var dino3IsDead : Bool = false
    
    var dino4: Dino!
    
    var foodX: Int!
    var foodY: Int!
    var foodTimer: NSTimer!
    
    var rocks: Int!
    var rockTimer: NSTimer!
    var stars: Int!
    
    var starX: Int!
    var starY: Int!
    
    var hearts: Int!
    var batteryPercent: Int!
    var batteryTimer: NSTimer!
    
    var touchLocation: CGPoint!
    var touchTime: CFTimeInterval!
    
    var gravityWarningTimer: NSTimer!
    var gravityOnTimer: NSTimer!
    var gravityOffTimer: NSTimer!
    
    struct BodyType {
        static let player: UInt32 = 0x1 << 0
        static let block: UInt32 = 0x1 << 1
        static let dino1: UInt32 = 0x1 << 2
        static let dino2: UInt32 = 0x1 << 3
        static let dino3: UInt32 = 0x1 << 4
        static let dino4: UInt32 = 0x1 << 5
        static let rock: UInt32 = 0x1 << 6
        static let enemy : UInt32 = 0x1 << 7
        static let scene: UInt32 = 0x1 << 8
        static let fireBall: UInt32 = 0x1 << 9
        static let playerMask: UInt32 = 0x1 << 10
        static let star: UInt32 = 0x1 << 11
        static let food: UInt32 = 0x1 << 12
        static let water: UInt32 = 0x1 << 13
        static let randomBlock: UInt32 = 0x1 << 14
    }
    
    //general set up for the game when the scene is presented
    override func didMoveToView(view: SKView) {
        updateStatusPanel("Hello! Welcome to the Thunderdome!")
        
        physicsWorld.contactDelegate = self
        
        applyPhysicsToCharacterAndWater()
        applyGestureRecognizers(view)
        addDinos()
        addMusic()
        
        
        createRandomGrid()
        
        addStar()
        addFood()
        
        
        setupPlayerStats()
        setupTimers()
        
        
        
    }
    
    //detects the touch and records the time
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        let touch = touches.first
        let location = touch!.locationInNode(self)
            touchLocation = location
            touchTime = CACurrentMediaTime()
            
        
    }
    
    //if the touch ends before the touchTimeThreshold, player throws a rock in the direction of the click
    //helps determine between a swipe and a tape
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let TouchTimeThreshold: CFTimeInterval = 0.3
        //let TouchDistanceThreshold: CGFloat = 4
        
        if CACurrentMediaTime() - touchTime < TouchTimeThreshold {
            
           let touch = touches.first
                if rocks > 0 {
                let location = touch!.locationInNode(self)
                let player = self.childNodeWithName("player") as! SKSpriteNode
                
                
                let spriteRock = SKSpriteNode(imageNamed: "rock")
                spriteRock.position = CGPoint( x: player.position.x, y: player.position.y)
                spriteRock.size = CGSize(width: 30, height: 30)
                spriteRock.zPosition = 3
                
                let physicsBody = SKPhysicsBody(circleOfRadius: 15)
                physicsBody.affectedByGravity = false
                physicsBody.allowsRotation = true
                physicsBody.categoryBitMask = BodyType.rock
                physicsBody.contactTestBitMask = BodyType.rock | BodyType.dino1 | BodyType.dino2 | BodyType.dino3 | BodyType.dino4
                physicsBody.collisionBitMask = BodyType.playerMask
                spriteRock.physicsBody = physicsBody
                
                self.addChild(spriteRock)
                
                
                var dx = location.x - player.position.x
                var dy = location.y - player.position.y
                
                let magnitude = sqrt(dx*dx+dy*dy)
                dx /= magnitude
                dy /= magnitude
                
                let vector = CGVectorMake(10*dx, 10*dy)
                
                spriteRock.physicsBody?.applyImpulse(vector)
                rocks = rocks - 1
                updateStats()
                
                self.runAction(shootSound)
                    
                }

            
        }
        
    }
    
    
    //handles all the contact between physicsbody's in the GameScene
    func didBeginContact(contact: SKPhysicsContact){
        
        let player = self.childNodeWithName("player")
        if (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.randomBlock) || (contact.bodyA.categoryBitMask == BodyType.randomBlock && contact.bodyB.categoryBitMask == BodyType.player){
           // print("player ran into a random block!")
            player?.removeAllActions()
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.star) || (contact.bodyA.categoryBitMask == BodyType.star && contact.bodyB.categoryBitMask == BodyType.player){
            //print("player got a star!")
            updateStatusPanel("WHOA! YOU GOT A STAR!")
            //player?.removeAllActions()
            if contact.bodyA.categoryBitMask == BodyType.star {
                contact.bodyA.node?.removeFromParent()
            }else {
                contact.bodyB.node?.removeFromParent()
            }
            stars = stars + 1
            self.objectGrid[starX][starY] = 0
            addStar()
            updateStats()
            self.runAction(starSound)
            //playSound("celebration.wav")
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.dino1 && contact.bodyB.categoryBitMask == BodyType.player) || (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.dino1){
            //print("dino1 hit the player!")
            //player?.removeAllActions()
            self.runAction(punchSound)
            applyDamage(60)
            checkIfAlive()
            
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.dino2 && contact.bodyB.categoryBitMask == BodyType.player) || (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.dino2) {
            //print("dino2 hit the player!")
            //player?.removeAllActions()
            self.runAction(punchSound)
            applyDamage(80)
            checkIfAlive()
        
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.dino3 && contact.bodyB.categoryBitMask == BodyType.player) || (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.dino3) {
            //print("dino3 hit the player!")
            // player?.removeAllActions()
            self.runAction(punchSound)
            applyDamage(100)
            checkIfAlive()
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.dino3 && contact.bodyB.categoryBitMask == BodyType.block) || (contact.bodyA.categoryBitMask == BodyType.block && contact.bodyB.categoryBitMask == BodyType.dino3) {
            // print("dino3 finding new direction.....")
            Dino3Movement()
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.dino3 && contact.bodyB.categoryBitMask == BodyType.randomBlock) || (contact.bodyA.categoryBitMask == BodyType.randomBlock && contact.bodyB.categoryBitMask == BodyType.dino3) {
            // print("dino3 finding new direction.....")
            Dino3Movement()
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.dino3 && contact.bodyB.categoryBitMask == BodyType.water) || (contact.bodyA.categoryBitMask == BodyType.water && contact.bodyB.categoryBitMask == BodyType.dino3) {
            // print("dino3 finding new direction.....")
            Dino3Movement()
        }


        
        if (contact.bodyA.categoryBitMask == BodyType.fireBall && contact.bodyB.categoryBitMask == BodyType.player) || (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.fireBall) {
            //print("player got hit by a fireball!")
            
            if contact.bodyA.categoryBitMask == BodyType.fireBall {
                contact.bodyA.node?.removeFromParent()
            }else {
                contact.bodyB.node?.removeFromParent()
            }
            // player?.removeAllActions()
            self.runAction(punchSound)
            applyDamage(100)
            checkIfAlive()
            
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.rock && contact.bodyB.categoryBitMask == BodyType.dino1) || (contact.bodyA.categoryBitMask == BodyType.dino1 && contact.bodyB.categoryBitMask == BodyType.rock) {
            
           // print("dino1 is kill")
            updateStatusPanel("Dino1 has died! Nice Shot!")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            
            let randomInterval = arc4random_uniform(5) + 1
            dino1Timer = NSTimer.scheduledTimerWithTimeInterval(Double(randomInterval), target: self, selector: Selector("addDino1"), userInfo: nil, repeats: false)
            self.runAction(dinoHitSound)
            
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.rock && contact.bodyB.categoryBitMask == BodyType.dino2) || (contact.bodyA.categoryBitMask == BodyType.dino2 && contact.bodyB.categoryBitMask == BodyType.rock) {
            
            //print("dino2 is kill")
            updateStatusPanel("Dino2 has died! Nice Shot!")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            
            let randomInterval = arc4random_uniform(5) + 1
            dino2Timer = NSTimer.scheduledTimerWithTimeInterval(Double(randomInterval), target: self, selector: Selector("addDino2"), userInfo: nil, repeats: false)
            self.runAction(dinoHitSound)

        }
        
        if (contact.bodyA.categoryBitMask == BodyType.rock && contact.bodyB.categoryBitMask == BodyType.dino3) || (contact.bodyA.categoryBitMask == BodyType.dino3 && contact.bodyB.categoryBitMask == BodyType.rock) {
            
            //print("dino3 is kill")
            updateStatusPanel("Dino3 has died! Nice Shot!")
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            
            let randomInterval = arc4random_uniform(5) + 1
            dino3IsDead = true
            dino3Timer = NSTimer.scheduledTimerWithTimeInterval(Double(randomInterval), target: self, selector: Selector("addDino3"), userInfo: nil, repeats: false)
            self.runAction(dinoHitSound)
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.food && contact.bodyB.categoryBitMask == BodyType.player) || (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.food) {
           //print("player got some food!")
            
            if contact.bodyA.categoryBitMask == BodyType.food {
                contact.bodyA.node?.removeFromParent()
            }else {
                contact.bodyB.node?.removeFromParent()
            }
            // player?.removeAllActions()
            batteryPercent = batteryPercent + 50
            self.objectGrid[foodX][foodY] = 0
            updateStats()
            addFood()
            self.runAction(eatSound)
            //applyDamage(100)
            //checkIfAlive()
            
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.water && contact.bodyB.categoryBitMask == BodyType.player) || (contact.bodyA.categoryBitMask == BodyType.player && contact.bodyB.categoryBitMask == BodyType.water) {
            //print("player drowned!")
            
            moveToGameOverScene()
            
        }
        
        if (contact.bodyA.categoryBitMask == BodyType.food && contact.bodyB.categoryBitMask == BodyType.dino1) || (contact.bodyA.categoryBitMask == BodyType.dino1 && contact.bodyB.categoryBitMask == BodyType.food) {
            //print("dinosaur ate the food!")
            
            if contact.bodyA.categoryBitMask == BodyType.food {
                contact.bodyA.node?.removeFromParent()
            }else {
                contact.bodyB.node?.removeFromParent()
            }

            
            self.objectGrid[foodX][foodY] = 0
            foodTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("addFood"), userInfo: nil, repeats: false)
            //print(foodTimer.timeInterval.description)
            self.runAction(eatSound)

            
        }

        if (contact.bodyA.categoryBitMask == BodyType.food && contact.bodyB.categoryBitMask == BodyType.dino2) || (contact.bodyA.categoryBitMask == BodyType.dino2 && contact.bodyB.categoryBitMask == BodyType.food) {
           // print("dinosaur ate the food!")
            
            if contact.bodyA.categoryBitMask == BodyType.food {
                contact.bodyA.node?.removeFromParent()
            }else {
                contact.bodyB.node?.removeFromParent()
            }
            
            
            self.objectGrid[foodX][foodY] = 0
            foodTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("addFood"), userInfo: nil, repeats: false)
            self.runAction(eatSound)

        }
        
        if (contact.bodyA.categoryBitMask == BodyType.food && contact.bodyB.categoryBitMask == BodyType.dino3) || (contact.bodyA.categoryBitMask == BodyType.dino3 && contact.bodyB.categoryBitMask == BodyType.food) {
            //print("dinosaur ate the food!")
            
            if contact.bodyA.categoryBitMask == BodyType.food {
                contact.bodyA.node?.removeFromParent()
            }else {
                contact.bodyB.node?.removeFromParent()
            }
            
            
            self.objectGrid[foodX][foodY] = 0
            foodTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("addFood"), userInfo: nil, repeats: false)
            self.runAction(eatSound)

        }
    }
   
    
    override  func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    //gesture recognizers for each swipe direction
    func swipedRight(sender:UISwipeGestureRecognizer){
        let player = self.childNodeWithName("player") as! SKSpriteNode
        player.removeAllActions()
        changePlayerDirection(player, direction: "right")
        player.runAction(SKAction.repeatActionForever(right))
    }
    func swipedLeft(sender:UISwipeGestureRecognizer){
        let player = self.childNodeWithName("player") as! SKSpriteNode
        player.removeAllActions()
        changePlayerDirection(player, direction: "left")
        player.runAction(SKAction.repeatActionForever(left))
    }
    func swipedUp(sender:UISwipeGestureRecognizer){
        let player = self.childNodeWithName("player") as! SKSpriteNode
        player.removeAllActions()
        player.runAction(SKAction.repeatActionForever(up))
    }
    func swipedDown(sender:UISwipeGestureRecognizer){
        let player = self.childNodeWithName("player") as! SKSpriteNode
        player.removeAllActions()
        player.runAction(SKAction.repeatActionForever(down))
    }
    
    //changes the direction the player is facing
    //used in the swipe gesture recognizers
    func changePlayerDirection(player: SKSpriteNode, direction: String){
        if ((player.xScale < 0 && direction == "left") || (player.xScale > 0 && direction == "right")) {
            player.xScale = player.xScale * -1
        }
    }
    
    //used in didMoveToView
    //applies physicsBodies to the water block and the player sprites
    func applyPhysicsToCharacterAndWater(){
        
        let player = self.childNodeWithName("player")
        let playerPhysicsBody = SKPhysicsBody(circleOfRadius: (player!.frame.height/2))
        playerPhysicsBody.affectedByGravity = false
        playerPhysicsBody.dynamic = true
        playerPhysicsBody.categoryBitMask = BodyType.player
        playerPhysicsBody.contactTestBitMask = BodyType.player | BodyType.block | BodyType.randomBlock
        playerPhysicsBody.collisionBitMask = BodyType.block | BodyType.randomBlock
        playerPhysicsBody.allowsRotation = false
        
        player?.physicsBody = playerPhysicsBody
        
        let water1 = self.childNodeWithName("water1")
        
        let physicsBody = SKPhysicsBody(rectangleOfSize: water1!.frame.size)
        physicsBody.dynamic = false
        physicsBody.pinned = true
        physicsBody.affectedByGravity = false
        physicsBody.allowsRotation = false
        physicsBody.categoryBitMask = BodyType.water
        physicsBody.contactTestBitMask = BodyType.player | BodyType.water
        
        water1?.physicsBody = physicsBody
        
        let water2 = self.childNodeWithName("water2")
        
        let physicsBody2 = SKPhysicsBody(rectangleOfSize: water2!.frame.size)
        physicsBody2.dynamic = false
        physicsBody2.pinned = true
        physicsBody2.affectedByGravity = false
        physicsBody2.allowsRotation = false
        physicsBody2.categoryBitMask = BodyType.water
        physicsBody2.contactTestBitMask = BodyType.player | BodyType.water
        
        water2?.physicsBody = physicsBody2
        
        
    }
    
    //applies gestureRecognizers in didMoveToView
    func applyGestureRecognizers(view: SKView){
        let swipeRight:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedRight:"))
        swipeRight.direction = .Right
        view.addGestureRecognizer(swipeRight)
        
        let swipeLeft:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedLeft:"))
        swipeLeft.direction = .Left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeUp:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedUp:"))
        swipeUp.direction = .Up
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipedDown:"))
        swipeDown.direction = .Down
        view.addGestureRecognizer(swipeDown)
        
    }
    
    //checks if the player is still alive
    //if not, moves to the game over scene
    func checkIfAlive(){
        if hearts <= 0 {
            moveToGameOverScene()
        }
    }

    // checks the time for the random block generation
    //if blockCount is less than 15, it generates a random block
    //otherwise the timer that runs this method is invalidated and random block generation stops
    func checkTimeForBlocks(){
        if blockCount < 15 {
            generateRandomBlock()
        } else {
            self.blockTimer.invalidate()
        }
        blockCount++
    }
    
    //sets up the object grid.  Used in didMoveToView for initial setup
    func createRandomGrid(){
        objectGrid = [[Int]](count: 16, repeatedValue: [Int](count: 9, repeatedValue: 0 ))
        objectGrid[0][0] = 1
        objectGrid[15][8] = 1
        blockTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("checkTimeForBlocks"), userInfo: nil, repeats: true)
    }
    
    //creates and adds a random block to a random spot on the object grid only if the position isn't occupied by the player or dino3
    func generateRandomBlock(){
        let x = Int(arc4random_uniform(16))
        let y = Int(arc4random_uniform(9))
        
        let player = self.childNodeWithName("player") as! SKSpriteNode
        
        
        
        
        if self.objectGrid[x][y] == 0  {
            let randomBlock = SKSpriteNode(imageNamed: "block")
            
            
            randomBlock.size = CGSize(width: 64, height: 64)
            randomBlock.position = CGPoint(x: (x*64) + 32,y: ((y+1)*64) + 32)
           /* randomBlock.physicsBody?.pinned = true
            randomBlock.physicsBody?.allowsRotation = false
            randomBlock.physicsBody?.affectedByGravity = false*/
            randomBlock.zPosition = 1
            
            let physicsBody = SKPhysicsBody(rectangleOfSize:randomBlock.frame.size)
            physicsBody.affectedByGravity = false
            physicsBody.allowsRotation = false
            physicsBody.pinned = true
            physicsBody.categoryBitMask = BodyType.randomBlock
            physicsBody.contactTestBitMask = BodyType.block | BodyType.player | BodyType.dino3
            physicsBody.collisionBitMask = BodyType.player
            randomBlock.physicsBody = physicsBody
            
            if (CGRectContainsRect(randomBlock.frame, player.frame) || CGRectContainsRect(randomBlock.frame, dino3.frame))
            {
                generateRandomBlock()
            }
            else {
                self.addChild(randomBlock)
                self.objectGrid[x][y] = 1
            }
        } else {
            generateRandomBlock()
        }
    }
    
    
    // adds a star to a random position on the object grid not occupied by another object
    func addStar(){
        
        starX = Int(arc4random_uniform(16))
        starY = Int(arc4random_uniform(9))
        
        if self.objectGrid[starX][starY] == 0 {
            let star = SKSpriteNode(imageNamed: "star")
            
            star.size = CGSize(width: 64, height: 64)
            star.position = CGPoint(x: (starX*64) + 32, y: ((starY+1)*64) + 32)
            star.zPosition = 1
            let physicsBody = SKPhysicsBody(rectangleOfSize:star.frame.size)
            physicsBody.affectedByGravity = false
            physicsBody.allowsRotation = false
            physicsBody.pinned = true
            physicsBody.categoryBitMask = BodyType.star
            physicsBody.contactTestBitMask = BodyType.star | BodyType.player | BodyType.dino3
            physicsBody.collisionBitMask = BodyType.playerMask
            star.physicsBody = physicsBody
            
            self.addChild(star)
            self.objectGrid[starX][starY] = 1
            
        } else {
            addStar()
        }
    }
    
    // adds a piece of food to a random position on the object grid not occupied by another object
    func addFood(){
        
        
        foodX =  Int(arc4random_uniform(16))
        foodY = Int(arc4random_uniform(9))
        
        if self.objectGrid[foodX][foodY] == 0 {
            let food = SKSpriteNode(imageNamed: "food")
            
            food.size = CGSize(width: 64, height: 64)
            food.position = CGPoint(x: (foodX*64) + 32, y: ((foodY+1)*64) + 32)
            food.zPosition = 1
            
            let physicsBody = SKPhysicsBody(rectangleOfSize:food.frame.size)
            physicsBody.affectedByGravity = false
            physicsBody.allowsRotation = false
            physicsBody.pinned = true
            physicsBody.categoryBitMask = BodyType.food
            physicsBody.contactTestBitMask = BodyType.food | BodyType.star | BodyType.player | BodyType.dino3 | BodyType.dino1 | BodyType.dino2
            physicsBody.collisionBitMask = BodyType.playerMask
            food.physicsBody = physicsBody
            
            self.addChild(food)
            self.objectGrid[foodX][foodY] = 1
            
            //foodTimer?.invalidate()
            //print("added food")
        } else{
            addFood()
        }

    }
    
    // adds background music to the scene
    func addMusic(){
        let backgroundMusic =  SKAudioNode(fileNamed: "Splint.mp3")
        backgroundMusic.autoplayLooped = true
        self.addChild(backgroundMusic)
    }
    
    // each time dino3 runs into a block or the player, dino3 moves in a random direction
    func Dino3Movement(){
        dino3.removeAllActions()
        
        let randomDirection = Int(arc4random_uniform(4))
        
        if  dino3Direction == randomDirection {
            Dino3Movement()
        }
        else {
        
        dino3Direction = randomDirection
            var point: CGPoint = CGPoint(x: 0, y: 0)
            let movement: SKAction!
        switch randomDirection {
        case 0 :
            point = CGPoint(x: 1200, y: Int(arc4random_uniform(800)))
            movement = SKAction.moveTo(point, duration: 1.5)
                        break
        case 1 :
             point = CGPoint(x: Int(arc4random_uniform(1200)), y: 800)
            movement = SKAction.moveTo(point, duration: 1.5)
            break
        case 2 :
            let point = CGPoint(x: 0, y: Int(arc4random_uniform(1200)))
             movement = SKAction.moveTo(point, duration: 1.5)
            break
        case 3 :
            let point = CGPoint(x: Int(arc4random_uniform(1200)), y: 0)
            movement = SKAction.moveTo(point, duration: 1.5)
            break
        default :
            point = CGPoint(x: 0,y: 0)
            movement = SKAction.rotateByAngle(3, duration: 1.5)
            break
            }
            
            if (point.x > dino3.position.x) {
                dino3.xScale = 1
            } else  {
                dino3.xScale = -1
            }

            
            movement.speed = 0.3
            movement.timingMode = .Linear
            dino3.runAction(movement)
        }
    }
    
    //I had some trouble with dino3 randomly disappearing from the scene
    //This method runs on a timer and checks to make sure dino3 is in the scene, if not, removes dino3 from the scene and respawns him
    func checkDino3Position(){
        
        let background = self.childNodeWithName("background")
        
        if(CGRectContainsPoint(background!.frame, dino3.position))
        {
        
        } else if (dino3IsDead == false){
            dino3.removeFromParent()
            addDino3()
            Dino3Movement()

        }
    }
    
    //functions used to add dinos to the scene, define their physics bodies, and defines their actions
    func addDino1(){
        dino1Timer?.invalidate()
        //print("spawned dino1")
         dino1 = Dino(image: "dino1", xDim: 50, yDim: 50, damage: 60, name: "dino1")
        
        dino1.zPosition = 2
        let physicsBody = SKPhysicsBody(rectangleOfSize: dino1.frame.size)
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = BodyType.dino1
        physicsBody.contactTestBitMask = BodyType.player | BodyType.dino1 | BodyType.rock
        physicsBody.collisionBitMask = BodyType.enemy //| BodyType.playerMask
        dino1.physicsBody = physicsBody
        
        let dino1PositionDecider = arc4random_uniform(2)
        //print(dino1PositionDecider)
        if dino1PositionDecider == 0 {
            dino1.position = CGPoint(x: 352, y: 32)
        }else{
            dino1.position = CGPoint(x: 736, y: 32)
        }
        
        
        let moveUp = SKAction.moveByX(0, y: 600, duration: 3)
        let MoveDown  = SKAction.moveByX(0, y: -600, duration: 3)
        let wait = SKAction.waitForDuration(2, withRange: 2)
        
        var sequence = SKAction.sequence([moveUp, MoveDown, wait])
        sequence = SKAction.repeatActionForever(sequence)
        
        //let dino1Action = SKAction(named: "dino1Action")
        
        self.addChild(dino1)
        dino1.runAction(sequence)
        
        
    }
    func addDino2(){
         dino2 = Dino(image: "dino2", xDim: 64, yDim: 64, damage: 80, name: "dino2")
        dino2.zPosition = 2
        
        let physicsBody = SKPhysicsBody(rectangleOfSize: dino2.frame.size)
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = BodyType.dino2
        physicsBody.contactTestBitMask = BodyType.player | BodyType.dino2 | BodyType.rock
        physicsBody.collisionBitMask = BodyType.enemy// | BodyType.playerMask

        dino2.physicsBody = physicsBody
        
        let dino2PositionDecider = Int(arc4random_uniform(9))
        
        dino2.position = CGPoint(x: 992, y: ((dino2PositionDecider + 1)*64) + 32)
        
        let moveLeft = SKAction.moveByX(-970, y: 0, duration: 4)
        let changeDirection = SKAction.runBlock{
            self.dino2.xScale = self.dino2.xScale * -1
        }
        let moveRight = SKAction.moveByX(970, y: 0, duration: 4)
        let wait = SKAction.waitForDuration(2, withRange: 2)
        var sequence = SKAction.sequence([moveLeft, changeDirection, moveRight, changeDirection, wait])
        sequence = SKAction.repeatActionForever(sequence)
        
        self.addChild(dino2)
        dino2.runAction(sequence)
        
        dino2Timer?.invalidate()
    }
    func addDino3(){
        print("dino3 has spawned")
        dino3Timer?.invalidate()
        dino3IsDead = false
        
        dino3 = Dino(image: "dino3", xDim: 60, yDim: 60, damage: 100, name: "dino3")
        
        dino3.zPosition = 3
        
        dino3.position = CGPoint(x: 992, y: 608)
        dino3Direction = 99
        
        
        let physicsBody = SKPhysicsBody(rectangleOfSize: dino3.frame.size)
        physicsBody.affectedByGravity = false
        physicsBody.categoryBitMask = BodyType.dino3
        physicsBody.allowsRotation = false
        physicsBody.friction = 0
        physicsBody.restitution = 1
        
        physicsBody.contactTestBitMask = BodyType.player | BodyType.rock | BodyType.block | BodyType.randomBlock | BodyType.water
        physicsBody.collisionBitMask = BodyType.player | BodyType.block | BodyType.randomBlock
        
        dino3.physicsBody = physicsBody
        
        self.addChild(dino3)
        Dino3Movement()
        
    }
    func addDino4(){
        dino4 = Dino(image: "dino4", xDim: 64, yDim: 64, damage: 100, name: "dino4")
        dino4.zPosition = 3
        
        dino4.position = CGPoint(x: 32, y: 672)
        
        let moveRight = SKAction.moveByX(960, y: 0, duration: 4)
        let moveLeft = SKAction.moveByX(-960, y: 0, duration: 4)
        
        var sequence = SKAction.sequence([moveRight,moveLeft])
        sequence = SKAction.repeatActionForever(sequence)
        
        let throwfireball = SKAction.runBlock{
            let fireBall = SKSpriteNode(imageNamed: "fire")
            fireBall.position = CGPoint(x: self.dino4.position.x, y: 672 - 64)
            fireBall.zPosition = 1
            fireBall.size = CGSize(width: 64, height: 64)
            
            let physicsBody = SKPhysicsBody(circleOfRadius: 32)
            physicsBody.affectedByGravity = false
            physicsBody.allowsRotation = false
            physicsBody.categoryBitMask = BodyType.fireBall
            physicsBody.contactTestBitMask = BodyType.fireBall | BodyType.player
            physicsBody.collisionBitMask = BodyType.player //| BodyType.playerMask
            
            fireBall.physicsBody = physicsBody
            
            self.addChild(fireBall)
            fireBall.runAction(SKAction.repeatActionForever(SKAction.moveByX(0, y: -64, duration: 0.4)))
        }
        let wait = SKAction.waitForDuration(10, withRange:  5)
        
        
        var sequence2 = SKAction.sequence([wait, throwfireball])
        sequence2 = SKAction.repeatActionForever(sequence2)
        self.addChild(dino4)
        
        dino4.runAction(sequence)
        dino4.runAction(sequence2)
    }
    
    // function used during setup to add all dinos to the scene during didMoveToView
    func addDinos(){
        addDino1()
        addDino2()
        addDino3()
        addDino4()
    }
    
    // used in didBeginContact.
    // If player is contacted by dino 1-3 or hit by a fireball, damage is applied to the players stats
    func applyDamage(damage: Int) {
        if damage > batteryPercent {
            batteryPercent = 100 - (damage - batteryPercent)
            hearts = hearts - 1
        }
        else{
            batteryPercent = batteryPercent - damage
        }
        updateStats()
    }
    
    
    // function ran by a timer every second.  Checks player's stats and decrements them accordingly
    func checkTimeForPlayer(){
        if batteryPercent > 0 && hearts > 0 {
            batteryPercent = batteryPercent - 1
            
        }
        
        if batteryPercent == 0 && hearts > 1 {
            batteryPercent = 100
            hearts = hearts - 1
        } else if (batteryPercent <= 0 && hearts <= 1){
            print("game is over!")
            batteryTimer.invalidate()
            moveToGameOverScene()
        }

        
        updateStats()
        //print(foodTimer?.timeInterval.description)
        
    }
    
    // function ran by a timer every 30 seconds.  sets player's rock count to 20
    func addRocks(){
        rocks = 20
        updateStats()
    }
    
    //updates the player stats label to the values saved in the game scene
    func updateStats(){
        
        let starLabel = self.childNodeWithName("starCount") as! SKLabelNode
        starLabel.text = String(stars)
        
        let rockLabel = self.childNodeWithName("rockCount") as! SKLabelNode
        rockLabel.text = String(rocks)
        
        if (batteryPercent > 100) && (hearts < 3) {
            hearts = hearts + 1
            batteryPercent = batteryPercent - 100
        }
        else if (batteryPercent > 300) && (hearts == 3) {
            batteryPercent = 300
        }
        
        let heartLabel = self.childNodeWithName("heartCount") as! SKLabelNode
        heartLabel.text = String(hearts)
        
        let batteryLabel = self.childNodeWithName("batteryCount") as! SKLabelNode
        batteryLabel.text = String(batteryPercent)
        
        
        
    }
    
    //presents game over scene if player dies
    func moveToGameOverScene(){
       
        let transition = SKTransition.revealWithDirection(.Down, duration: 1.0)
        
        let nextScene = GameOverScene(size: scene!.size)
        nextScene.scaleMode = .AspectFill
        self.paused = true
        //self.removeAllChildren()
        nextScene.gameScene = self
        nextScene.score = stars
        scene?.view?.presentScene(nextScene, transition: transition)

        
    }
    
    
    //warns player about gravity time happening by updating the status panel a couple seconds before gravity is turned on
    func gravityWarning(){
        updateStatusPanel("Gravity time is coming!")
        gravityWarningTimer.invalidate()
    }
    
    //ran on a timer every 40-60 seconds.  gravity for the player is turned on for 1 second
    func gravityOn(){
        let player = self.childNodeWithName("player")
        player?.physicsBody?.affectedByGravity = true
        gravityOnTimer.invalidate()
        gravityOffTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("gravityOff"), userInfo: nil, repeats: false)
    }
    
    // turns gravity off for a player 1 second after gravity is turned on
    func gravityOff(){
        let player = self.childNodeWithName("player")
        player?.physicsBody?.affectedByGravity = false
        gravityOffTimer.invalidate()
        
        let randomTime = Double(arc4random_uniform(21) + 40)
        gravityWarningTimer = NSTimer.scheduledTimerWithTimeInterval(randomTime - 3, target: self, selector:  Selector("gravityWarning"), userInfo: nil, repeats: false)
        gravityOnTimer = NSTimer.scheduledTimerWithTimeInterval(randomTime, target: self, selector:  Selector("gravityOn"), userInfo: nil, repeats: false)
    }
    
    //updates the status panel with the string that is passed to it
    func updateStatusPanel(message: String){
        let statusLabel = self.childNodeWithName("statusPanel") as! SKLabelNode
        statusLabel.text = message
    }
    
    //sets up all the necessary timers.  used in didMoveToView
    func setupTimers(){
        batteryTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("checkTimeForPlayer"), userInfo: nil, repeats: true)
        rockTimer = NSTimer.scheduledTimerWithTimeInterval(30.0, target:  self, selector: Selector("addRocks"), userInfo: nil, repeats: true)
        
        let randomTime: Double = Double(arc4random_uniform(21) + 40)
        
        gravityWarningTimer = NSTimer.scheduledTimerWithTimeInterval(randomTime - 3, target: self, selector:  Selector("gravityWarning"), userInfo: nil, repeats: false)
        gravityOnTimer = NSTimer.scheduledTimerWithTimeInterval(randomTime, target: self, selector:  Selector("gravityOn"), userInfo: nil, repeats: false)
        
        dino3PositionTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("checkDino3Position"), userInfo: nil, repeats: true)

    }
    
    // sets up the players stat in didMoveToView
    func setupPlayerStats(){
        rocks = 10
        stars = 0
        hearts = 3
        batteryPercent = 100

    }
    

}


//used for the transition between the gameOverScene and gameScene to load the scene I created in the GameScene.sks
extension GameScene {
    class func unarchiveFromFile(file : NSString) -> GameScene? {
        if let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks") {
            do {
                let sceneData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
                
                archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
                let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
                archiver.finishDecoding()
                return scene
            } catch{
                print("something went wrong")
            }
        } else {
            return nil
        }
        return nil
    }
}



