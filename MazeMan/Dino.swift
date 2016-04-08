//
//  Dino.swift
//  MazeMan
//
//  Created by Paul McDonald  on 4/2/16.
//  Copyright © 2016 Paul McDonald . All rights reserved.
//

import Foundation
import SpriteKit

//Dino class for the gameScene enemies
class Dino: SKSpriteNode{
    var damage: Int
    init(image: String, xDim: Double, yDim: Double, damage: Int, name: String){
        self.damage = damage
       // self.name = name
        super.init(texture: SKTexture(imageNamed: image), color: UIColor.clearColor(), size: CGSize(width: xDim, height: yDim))
        self.name = name
            }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
}