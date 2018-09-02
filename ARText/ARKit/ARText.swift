//
//  ARText.swift
//  ARKeyboard
//
//  Created by Mark Zhong on 7/20/17.
//  Copyright © 2017 Mark Zhong. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
class ARText:SCNText{
    override init() {
        super.init()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    init(text:String,
        font:UIFont,
        color:UIColor,
        depth:CGFloat
        ){
        super.init()
        /*
        self.firstMaterial?.lightingModel = .physicallyBased
        self.firstMaterial?.diffuse.contents = UIImage(named: "Media.scnassets/scuffed-plastic4-alb.png")
        self.firstMaterial?.roughness.contents = UIImage(named: "Media.scnassets/scuffed-plastic-rough.png")
        self.firstMaterial?.metalness.contents = UIImage(named: "Media.scnassets/scuffed-plastic-metal.png")
        self.firstMaterial?.normal.contents = UIImage(named: "Media.scnassets/scuffed-plastic-normal.png")
        self.firstMaterial?.ambientOcclusion.contents = UIImage(named: "Media.scnassets/scuffed-plastic-ao.png")*/
        
        self.string = text
        self.extrusionDepth = depth
        self.font = font
        
        self.alignmentMode = kCAAlignmentCenter
        self.truncationMode = kCATruncationMiddle
        self.firstMaterial?.isDoubleSided = true
        self.firstMaterial!.diffuse.contents = color
        self.firstMaterial?.lightingModel = .physicallyBased
        //self.firstMaterial?.diffuse.contents = UIImage(named: "Media.scnassets/scuffed-plastic9-alb.png")
        self.firstMaterial?.roughness.contents = UIImage(named: "Media.scnassets/scuffed-plastic-rough.png")
        self.firstMaterial?.metalness.contents = UIImage(named: "Media.scnassets/scuffed-plastic-metal.png")
        self.firstMaterial?.normal.contents = UIImage(named: "Media.scnassets/scuffed-plastic-normal.png")
        self.firstMaterial?.ambientOcclusion.contents = UIImage(named: "Media.scnassets/scuffed-plastic-ao.png")
        
        self.flatness = 0.3
    
    }
    
}
