/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Coordinates movement and gesture interactions with virtual objects.
*/

import UIKit
import ARKit

class CreatObjectInteraction: NSObject, UIGestureRecognizerDelegate {
    
    /// Developer setting to translate assuming the detected plane extends infinitely.平面是否是无限的？
    let translateAssumingInfinitePlane = true
    
    /// 当移动虚拟内容时所需要考虑hit test的ScencView
    let sceneView: MyARView
    
    /**
     The object that has been most recently intereacted with.
     The `selectedObject` can be moved at any time with the tap gesture.
     最近交互的对象。
     selectedObject在任何时候都可以通过点击手势来移动。
     */
    var selectedObject: CreatObject?
    
    /// The object that is tracked for use by the pan and rotation gestures. 被平移和旋转手势跟踪的物体。
    private var trackedObject: CreatObject? {
        didSet {
            guard trackedObject != nil else { return }
            selectedObject = trackedObject
        }
    }
    
    /// The tracked screen position used to update the `trackedObject`'s position in `updateObjectToCurrentTrackingPosition()`. 跟踪屏幕位置用于在“updateObjectToCurrentTrackingPosition()”中更新trackedObject的位置。
    private var currentTrackingPosition: CGPoint?

    init(sceneView: MyARView) {
        self.sceneView = sceneView
        super.init()
        //初始化并绑定手势，使用新类来对pan手势做一个阈值的判断，有限处理旋转和单击手势
        let panGesture = ThresholdPanGesture(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        rotationGesture.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(rotationGesture)
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Gesture Actions
    
    @objc
    func didPan(_ gesture: ThresholdPanGesture) {
        switch gesture.state {
        case .began:
            // Check for interaction with a new object.
            if let object = objectInteracting(with: gesture, in: sceneView) {
                trackedObject = object
            }
        case .changed where gesture.isThresholdExceeded:
            guard let object = trackedObject else { return }
            let translation = gesture.translation(in: sceneView)
            
            let currentPosition = currentTrackingPosition ?? CGPoint(sceneView.projectPoint(object.position))
            
            // `currentTrackingPosition` 是用来更新 `selectedObject` 通过 `updateObjectToCurrentTrackingPosition()`.
            currentTrackingPosition = CGPoint(x: currentPosition.x + translation.x, y: currentPosition.y + translation.y)
            //每次移动都要记得将原点归零
            gesture.setTranslation(.zero, in: sceneView)
            
        case .changed:
            // Ignore changes to the pan gesture until the threshold for displacment has been exceeded.
            break
            
        default:
            // Clear the current position tracking.
            currentTrackingPosition = nil
            trackedObject = nil
        }
    }

    /**
     If a drag gesture is in progress, update the tracked object's position by
     converting the 2D touch location on screen (`currentTrackingPosition`) to
     3D world space.
     This method is called per frame (via `SCNSceneRendererDelegate` callbacks),
     allowing drag gestures to move virtual objects regardless of whether one
     drags a finger across the screen or moves the device through space.
     
     如果一个拖拽动作正在进行中，通过将屏幕上的2D触摸位置(currenttracking头寸)转换为3D世界空间来更新跟踪对象的位置。
     这个方法被称为每帧(通过SCNSceneRendererDelegate的回叫)，允许拖拽动作来移动虚拟对象，不管一个手指是否在屏幕上拖动，或者移动设备通过空间。
     - Tag: updateObjectToCurrentTrackingPosition
     */
    @objc
    func updateObjectToCurrentTrackingPosition() {
        guard let object = trackedObject, let position = currentTrackingPosition else {
            return }
        translate(object, basedOn: position, infinitePlane: translateAssumingInfinitePlane)
    }

    /// - Tag: didRotate
    @objc
    func didRotate(_ gesture: UIRotationGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        /*
         - Note:
          For looking down on the object (99% of all use cases), we need to subtract the angle.
          To make rotation also work correctly when looking from below the object one would have to
          flip the sign of the angle depending on whether the object is above or below the camera...
         */
        trackedObject?.eulerAngles.y -= Float(gesture.rotation)
        
        gesture.rotation = 0
    }
    
    @objc
    func didTap(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: sceneView)
        //单击屏幕有两种可能的操作，一是选择一个新的物体，二是选择了新的物体之后将物品传送至触摸点
        if let tappedObject = sceneView.creatObject(at: touchLocation) {
            selectedObject = tappedObject
        } else if let object = selectedObject {
            translate(object, basedOn: touchLocation, infinitePlane: false)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 允许对象同时进行两个手势：旋转、位移
        return true
    }

    /// A helper method to return the first object that is found under the provided `gesture`s touch locations.返回在触摸位置下的第一个对象。
    /// - Tag: TouchTesting
    private func objectInteracting(with gesture: UIGestureRecognizer, in view: MyARView) -> CreatObject? {
        for index in 0..<gesture.numberOfTouches {
            let touchLocation = gesture.location(ofTouch: index, in: view)
            
            // Look for an object directly under the `touchLocation`.
            if let object = sceneView.creatObject(at: touchLocation) {
                return object
            }
        }
        // As a last resort look for an object under the center of the touches.作为最后的手段，在触摸的中心下寻找一个物体。
        return sceneView.creatObject(at: gesture.center(in: view))
    }
    
    // MARK: - Update object position

    /**
     - Tag: DragVirtualObject
     @param object 虚拟物品
     @param basedOn 更新的地点
     @param infintePlane 无限平面？
     */
    private func translate(_ object: CreatObject, basedOn screenPos: CGPoint, infinitePlane: Bool) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform,
            let (position, _, isOnPlane) = sceneView.worldPosition(fromScreenPosition: screenPos,
                                                                   objectPosition: object.simdPosition,
                                                                   infinitePlane: infinitePlane) else { return }
        
        /*
         Plane hit test results are generally smooth. If we did *not* hit a plane,
         smooth the movement to prevent large jumps.平稳运动以防止大的跳跃。
         */
        object.setPosition(position, relativeTo: cameraTransform, smoothMovement: !isOnPlane)
    }
}

/// 扩展 `UIGestureRecognizer` ，添加一个属性，即多点触摸中多个触摸点的中心.
extension UIGestureRecognizer {
    func center(in view: UIView) -> CGPoint {
        let first = CGRect(origin: location(ofTouch: 0, in: view), size: .zero)

        let touchBounds = (1..<numberOfTouches).reduce(first) { touchBounds, index in
            return touchBounds.union(CGRect(origin: location(ofTouch: index, in: view), size: .zero))
        }

        return CGPoint(x: touchBounds.midX, y: touchBounds.midY)
    }
}
