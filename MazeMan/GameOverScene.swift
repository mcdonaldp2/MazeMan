//
//  GameOverScene.swift
//  MazeMan
//
//  Created by Paul McDonald  on 4/4/16.
//  Copyright © 2016 Paul McDonald . All rights reserved.
//

import UIKit
import SpriteKit

class GameOverScene: SKScene {
    

    let playerDeathSound = SKAction.playSoundFileNamed("wilhelm.wav", waitForCompletion: false)
    var score: Int!
    var gameScene = GameScene()
    var scoreArray: [Int]!

    //shows player's score for previous game as well as the top high scores loaded from NSDefaults
    override func didMoveToView(view: SKView) {
        self.runAction(playerDeathSound)
        
            let scoreLabel = SKLabelNode(fontNamed:"Chalkduster")
            scoreLabel.text = "GAME OVER! Your score was: " + String(score)
            scoreLabel.fontSize = 45
            scoreLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame) + 100)
        
            self.addChild(scoreLabel)
        
        
            scoreArray = retrieveData()
            overwriteData()
        
            let highScoreLabel = SKLabelNode(fontNamed: "Chalkduster")
            highScoreLabel.fontSize = 45
            highScoreLabel.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
            highScoreLabel.text = "High Scores:" + " \(scoreArray[0]), \(scoreArray[1]), \(scoreArray[2]) "
            //scoreArray = retrieveData()
            self.addChild(highScoreLabel)
        
            let playLabel = SKLabelNode(fontNamed: "Chalkduster")
            playLabel.fontSize = 45
            playLabel.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame) - 100)
            playLabel.text = "Click the screen to play again!"
        
            self.addChild(playLabel)
    }
    
    // if touch is detected, transition back to the GameScene
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
         let touch = touches.first
           _ = touch!.locationInNode(self)
            //touchLocation = location
            //touchTime = CACurrentMediaTime()
            
            // self.paused = true
            //            var scene = GameOverScene(fileNamed: "GameOverScene")!
            //            let transition = SKTransition.moveInWithDirection(.Right, duration: 1)
            //            self.view?.presentScene(scene, transition: transition)
            let transition = SKTransition.revealWithDirection(.Down, duration: 1.0)
            
            let nextScene = GameScene.unarchiveFromFile("GameScene")
            nextScene!.scaleMode = .AspectFill
            self.removeAllChildren()
            scene?.view?.presentScene(nextScene!, transition: transition)
            
        
    }
    
    // adds the score to the scoreArray saved in NSDefaults
    func overwriteData(){
        scoreArray.append(score)
        scoreArray = scoreArray.sort().reverse()
        
        NSUserDefaults.standardUserDefaults().setObject(scoreArray, forKey: "scoreArray")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        let data = NSUserDefaults.standardUserDefaults().arrayForKey("scoreArray")
        
        print(data!.count)
    }
    
    
    //retrieves the scoreArray from NSDefaults
    func retrieveData() -> [Int]{
        if let data = NSUserDefaults.standardUserDefaults().arrayForKey("scoreArray") as? [Int] {
            return data
        } else {
            NSUserDefaults.standardUserDefaults().setObject([0,0,0], forKey: "scoreArray")
            NSUserDefaults.standardUserDefaults().synchronize()
            return [0,0,0]
        }
       
    }
    
    

    
}

