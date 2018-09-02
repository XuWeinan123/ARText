import ARKit

class StatusViewController: UIViewController {
    // MARK: - Types
    
    enum MessageType {
        case trackingStateEscalation
        case planeEstimation
        case contentPlacement
        case focusSquare
        
        static var all: [MessageType] = [
            .trackingStateEscalation,
            .planeEstimation,
            .contentPlacement,
            .focusSquare
        ]
    }
    
    // MARK: - IBOutlets
    @IBOutlet weak var messagePanel: UIVisualEffectView!
    @IBOutlet weak var messagePanel2: UIVisualEffectView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageIcon: UIImageView!
    
    // MARK: - Properties
    
    /// Seconds before the timer message should fade out. Adjust if the app needs longer transient messages. 在计时器消息应该淡出的前几秒。调整应用程序是否需要更长的临时消息。
    private let displayDuration: TimeInterval = 3
    
    // Timer for hiding messages. 用来隐藏消息的计时器
    private var messageHideTimer: Timer?
    
    private var timers: [MessageType: Timer] = [:]
    
    override func viewWillAppear(_ animated: Bool) {
        messagePanel.layer.cornerRadius = 125
        messagePanel.layer.masksToBounds = true
        messagePanel2.layer.cornerRadius = 125
        messagePanel2.layer.masksToBounds = true
    }
    // MARK: - Message Handling
    
    func showMessage(_ text: String, autoHide: Bool = true) {
        // 取消之前的隐藏计时器。
        messageHideTimer?.invalidate()
        
        messageLabel.text = text
        
        // 确保状态显示。
        setMessageHidden(false, animated: true)
        
        if autoHide {
            messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false, block: { [weak self] _ in
                self?.setMessageHidden(true, animated: true)
            })
        }
        //设置图标
        var str:String
        switch text {
        case "初始化中":
            str = "初始化中"
        case "欢迎回来":
            str = "欢迎回来"
        case "检测到平面":
            str = "检测到平面"
        case "追踪受限\n运动过度":
            str = "运动过快"
        case "追踪受限\n细节过低":
            str = "细节过低"
        case "追踪不可用":
            str = "追踪不可用"
        case "追踪正常":
            str = "追踪正常"
        default:
            str = ""
        }
        messageIcon.image = UIImage(named: str)
    }
    
    ///inSeconds秒后显示
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
        cancelScheduledMessage(for: messageType)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [weak self] timer in
            self?.showMessage(text)
            timer.invalidate()
        })
        
        timers[messageType] = timer
    }
    
    func cancelScheduledMessage(`for` messageType: MessageType) {
        timers[messageType]?.invalidate()
        timers[messageType] = nil
    }
    
    func cancelAllScheduledMessages() {
        for messageType in MessageType.all {
            cancelScheduledMessage(for: messageType)
        }
    }
    
    // MARK: - ARKit
    
    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }
    
    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        cancelScheduledMessage(for: .trackingStateEscalation)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [unowned self] _ in
            self.cancelScheduledMessage(for: .trackingStateEscalation)
            
            var message = trackingState.presentationString
            if let recommendation = trackingState.recommendation {
                message.append(": \(recommendation)")
            }
            
            self.showMessage(message, autoHide: false)
        })
        
        timers[.trackingStateEscalation] = timer
    }
    
    // MARK: - Panel Visibility
    
    private func setMessageHidden(_ hide: Bool, animated: Bool) {
        // The panel starts out hidden, so show it before animating opacity.
        messagePanel.isHidden = false
        
        guard animated else {
            messagePanel.alpha = hide ? 0 : 1
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: {
            self.messagePanel.alpha = hide ? 0 : 1
        }, completion: nil)
    }
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "追踪不可用"
        case .normal:
            return "追踪正常"
        case .limited(.excessiveMotion):
            return "追踪受限\n运动过度"
        case .limited(.insufficientFeatures):
            return "追踪受限\n细节过低"
        case .limited(.initializing):
            return "初始化中"
        case .limited(.relocalizing):
            return "relocalizing"
        }
    }
    
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return ""
        case .limited(.insufficientFeatures):
            return ""
        default:
            return nil
        }
    }
}

