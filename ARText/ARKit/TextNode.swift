import UIKit
import SceneKit
import ARKit

class TextNode: CreatObject {
    //不知道为什么这个节点老是不能脚踏实地，所以我加上这么几个差量
    //问题搞定，减掉一点字体的descend
    var offset:float3{
        return float3(0, 0, 0)
    }
    var textFont:UIFont!
    private var recentTextNodeDistances = [Float]()
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    init(anchor:ARPlaneAnchor, scntext:SCNText, sceneView:MyARView, scale:CGFloat){
        super.init()
        textFont = scntext.font
        self.geometry = scntext
        self.setPivot()
        self.position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.y)
        self.scale = SCNVector3(scale, scale, scale)
    }
    init(hitResult: ARHitTestResult, scntext:SCNText, sceneView:MyARView, scale:CGFloat){
        super.init()
        textFont = scntext.font
        self.geometry = scntext
        self.setPivot()
        self.position = SCNVector3Make(hitResult.worldTransform.columns.3.x,hitResult.worldTransform.columns.3.y,hitResult.worldTransform.columns.3.z)
        self.scale = SCNVector3(scale, scale, scale)
    }
    init(fsPosition: float3, scntext:SCNText, sceneView:MyARView, scale:CGFloat){
        super.init()
        textFont = scntext.font
        self.geometry = scntext
        self.setPivot()
        self.position = SCNVector3Make(fsPosition.x+offset.x,fsPosition.y+offset.y,fsPosition.z+offset.z)
        //self.position = SCNVector3Make(0,0,0)
        self.scale = SCNVector3(scale, scale, scale)
    }
    //设置锚点
    func setPivot() {
        let minVec = self.boundingBox.min
        let maxVec = self.boundingBox.max
        let bound = SCNVector3Make(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
        //print("textFont.descender:\(textFont.descender)")
        self.pivot = SCNMatrix4MakeTranslation(bound.x / 2, -Float(textFont.descender), bound.z / 2)
    }
    
    /// - Tag: AdjustOntoPlaneAnchor 这个方法好像是用来保证渲染出的平面尽量和真实平面稳定的
    override func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) {
        super.adjustOntoPlaneAnchor(anchor, using: node, offset: offset)
    }
    /**
     Set the object's position based on the provided position relative to the `cameraTransform`.
     If `smoothMovement` is true, the new position will be averaged with previous position to
     avoid large jumps.
    
     根据cameraTransform所提供的相对位置来设置object的位置。如果smoothMovement为真，那么这个新位置将与之前的位置保持平均，以避免大的跳跃。
     */
    override func setPosition(_ newPosition: float3, relativeTo cameraTransform: matrix_float4x4, smoothMovement: Bool) {
        let newPosition = newPosition + offset
        super.setPosition(newPosition, relativeTo: cameraTransform, smoothMovement: smoothMovement)
    }
    
    
}
