//
//  CreatObject.swift
//  3DARKit初体验
//
//  Created by 二号机 on 2017/11/22.
//  Copyright © 2017年 徐炜楠. All rights reserved.
//  和VirtualObject不同，CreatObject是创造出来的虚拟内容而不是引用的虚拟内容

import SceneKit
import ARKit

class CreatObject: SCNNode{
    ///用来记录造物的名称
    var objectName:String = ""
    ///用来保存造物的最近距离
    private var recentCreatObjectDistances = [Float]()

    ///重置已保存的造物的最近距离
    func reset(){
        recentCreatObjectDistances.removeAll()
    }
    func setPosition(_ newPosition:float3,relativeTo cameraTransform:matrix_float4x4,smoothMovement:Bool){
        let cameraWorldPosition = cameraTransform.translation
        var positionOffsetFromCamera = newPosition - cameraWorldPosition
        
        //将移动限制在10米以内
        if simd_length(positionOffsetFromCamera)>10{
            positionOffsetFromCamera = simd_normalize(positionOffsetFromCamera)
            positionOffsetFromCamera *= 10
        }
        //在最近的十次更新中计算出物体的平均距离。注意，距离是从摄像机到内容的矢量，所以它只影响到物体的距离。平均值并不会使内容“滞后”。
        if smoothMovement{
            let hitTestResultDistance = simd_length(positionOffsetFromCamera)
            //添加最后的位置，保留10位小数
            recentCreatObjectDistances.append(hitTestResultDistance)
            recentCreatObjectDistances = Array(recentCreatObjectDistances.suffix(10))
            
            let averageDistance = recentCreatObjectDistances.average!
            let averagedDistancePosition = simd_normalize(positionOffsetFromCamera)*averageDistance
            simdPosition = cameraWorldPosition + averagedDistancePosition
        }else{
            simdPosition = cameraWorldPosition + positionOffsetFromCamera
        }
    }
    func setPosition(_ newPosition:float3,relativeTo cameraTransform:matrix_float4x4,smoothMovement:Bool,offset:float3){
        let newPosition = newPosition + offset
        setPosition(newPosition, relativeTo: cameraTransform, smoothMovement: smoothMovement)
    }
    //保证平面稳定
    func adjustOntoPlaneAnchor(_ anchor:ARPlaneAnchor,using node:SCNNode){
        //得到物体在平面坐标系中的位置
        let planePosition = node.convertPosition(position, from:parent)
        //保证物体在平面上
        guard planePosition.y != 0 else{return}
        //在平面的角上增加10%的公差
        let tolerance:Float = 0.1
        
        let minX:Float = anchor.center.x - anchor.extent.x/2 - anchor.extent.x*tolerance
        let maxX:Float = anchor.center.x + anchor.extent.x/2 - anchor.extent.x*tolerance
        let minZ:Float = anchor.center.z - anchor.extent.z/2 - anchor.extent.z*tolerance
        let maxZ:Float = anchor.center.z + anchor.extent.z/2 + anchor.extent.z*tolerance
        
        //保证物体在平面上
        guard  (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        //5cm以内
        let verticalAllowance: Float = 0.05
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        //使用动画让调整的过程变得温和
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
        }
    }
    func adjustOntoPlaneAnchor(_ anchor:ARPlaneAnchor,using node:SCNNode,offset:float3){
        //得到物体在平面坐标系中的位置
        let planePosition = node.convertPosition(position, from:parent)
        //保证物体在平面上
        guard planePosition.y != 0 else{return}
        //在平面的角上增加10%的公差
        let tolerance:Float = 0.1
        
        let minX:Float = anchor.center.x - anchor.extent.x/2 - anchor.extent.x*tolerance
        let maxX:Float = anchor.center.x + anchor.extent.x/2 - anchor.extent.x*tolerance
        let minZ:Float = anchor.center.z - anchor.extent.z/2 - anchor.extent.z*tolerance
        let maxZ:Float = anchor.center.z + anchor.extent.z/2 + anchor.extent.z*tolerance
        
        //保证物体在平面上
        guard  (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        //5cm以内
        let verticalAllowance: Float = 0.05
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        //使用动画让调整的过程变得温和
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            position.y = anchor.transform.columns.3.y+offset.y
            SCNTransaction.commit()
        }
    }
    /// 返回一个“CreatObject”，如果作为提供节点的祖先存在的话。
    static func existingObjectContainingNode(_ node: SCNNode) -> CreatObject? {
        if let virtualObjectRoot = node as? CreatObject {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return existingObjectContainingNode(parent)
    }
}
