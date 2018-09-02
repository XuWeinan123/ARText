/*
对UIPanGestureRecognizer进行改进，增加对阈值的判断
*/

import UIKit.UIGestureRecognizerSubclass

/**
 A custom `UIPanGestureRecognizer` to track when a translation threshold has been exceeded
 and panning should begin.
 
 - Tag: ThresholdPanGesture
 */
class ThresholdPanGesture: UIPanGestureRecognizer {
    
    /// Indicates whether the currently active gesture has exceeeded the threshold.表示当前活动的动作是否已经超越了
    private(set) var isThresholdExceeded = false
    
    /// Observe when the gesture's `state` changes to reset the threshold.添加一个观察者属性，手势结束时将isThresholdExceeded设为假
    override var state: UIGestureRecognizerState {
        didSet {
            switch state {
            case .began, .changed:
                break
                
            default:
                // Reset threshold check.
                isThresholdExceeded = false
            }
        }
    }
    
    /// Returns the threshold value that should be used dependent on the number of touches.返回阈值，当使用超过两个手指的时候。优先判断其他手势，因此阈值设高
    private static func threshold(forTouchCount count: Int) -> CGFloat {
        switch count {
        case 1: return 30
            
        default: return 60
        }
    }
    
    /// - Tag: touchesMoved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        let translationMagnitude = translation(in: view).length
        
        // 调整阈值
        let threshold = ThresholdPanGesture.threshold(forTouchCount: touches.count)
        
        if !isThresholdExceeded && translationMagnitude > threshold {
            isThresholdExceeded = true
            
            // Set the overall translation to zero as the gesture should now begin.重置中心点，因为该开始了。
            setTranslation(.zero, in: view)
        }
    }
}
