//
//  ViewController.swift
//  3DARKit初体验
//
//  Created by 徐炜楠 on 2017/11/9.
//  Copyright © 2017年 徐炜楠. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import EFColorPicker
import SVProgressHUD
//import ARCL
//import CoreLocation

class ARVC: UIViewController, ARSCNViewDelegate,UIPopoverPresentationControllerDelegate,EFColorSelectionViewControllerDelegate {
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var sceneView: MyARView!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var inputTextAndBtn: UIView!
    @IBOutlet weak var hiddenFSBtn: UIButton!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var isToggleTrue:Bool = false
    var isFSHidden:Bool = false
    var viewAnchor:ARPlaneAnchor!
    var focusSquare = FocusSquare()//找寻平面用的方块
    /// 用来显示状态的文字
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    /// 一个串行队列用于协调从场景中添加或删除节点。
    let updateQueue = DispatchQueue(label: "serialSceneKitQueue")
    /// 存下添加到平面中的所有立体text
    var textNodes = [TextNode]()
    //地板
    var floorNodes = [CreatObject]()
    //屏幕的中心点
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    var session: ARSession {
        return sceneView.session
    }
    /// 对手势操作进行懒加载
    lazy var virtualObjectInteraction = CreatObjectInteraction(sceneView: sceneView)
    /// 记录键盘尺寸
    var keyboard = CGRect()
    
    var image:UIImage!
    var sendView:UploadView!
    let popover = Popover()
    
    let online = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        aligment()//设置UI细节
        //初始化弹框
        initSendView()
        initSomeParameters()
        setupScene()//设置场景的一些参数
        //设置场景的内容
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        focusSquare.unhide()
        
        //设置键盘弹出的动画
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //改变方向后要做的第一件事.改变大小
        inputTextAndBtn.frame = CGRect(x: inputTextAndBtn.frame.origin.x, y: inputTextAndBtn.frame.origin.y, width: size.width, height: inputTextAndBtn.frame.height)
        inputText.frame = CGRect(x: 16, y: 6, width: size.width-105, height: 30)
        sendBtn.frame = CGRect(x: size.width-81, y: 6, width: 73, height: 30)
        //改变方向后要做的第二件事.改变输入框的位置
        inputTextAndBtn.frame.origin.y = size.height-42
        
    }
    func aligment(){
        //self.navigationController?.setNavigationBarHidden(true, animated: true)
        let width = self.view.frame.width
        let height = self.view.frame.height
        
        inputTextAndBtn.frame = CGRect(x: 0, y: height-42, width: width, height: 42.0)
        inputText.frame = CGRect(x: 16, y: 6, width: width-105, height: 30)
        sendBtn.frame = CGRect(x: width-81, y: 6, width: 73, height: 30)
        cancelBtn.frame = CGRect(x: 50, y: 26, width: 32, height: 32)
        
        if(width>height){
            statusView.frame = CGRect(x: 431, y: 277, width: 250, height: 250)
        }else{
            statusView.frame = CGRect(x: 299, y: 422, width: 250, height: 250)
        }
        
        isFSHidden = UserDefaults.standard.bool(forKey: "isFSHidden")
        if isFSHidden{
            hiddenFSBtn.setImage(UIImage(named: "方块隐藏"), for: UIControlState.normal)
            focusSquare.isHidden = true
        }else{
            hiddenFSBtn.setImage(UIImage(named: "方块"), for: UIControlState.normal)
            focusSquare.isHidden = false
        }
        //如果是离线模式，那么把返回按钮隐藏
        if !online{
            cancelBtn.isHidden = true
        }
    
    }
    func initSendView(){
        sendView = UploadView.newInstance(frame: CGRect(x: 0, y: 0, width: self.view.frame.width-100, height: 540))
        sendView.removeBtn.isHidden = true
        //sendView.publishBtn.addTarget(self, action: #selector(publishBtnClick), for: UIControlEvents.touchUpInside)
        //如果是离线模式，将发表按钮变成存储到相册按钮
        if !online{
            sendView.offlineMode()
            sendView.saveBtn.addTarget(self, action: #selector(saveBtnClick), for: UIControlEvents.touchUpInside)
        }
    }
    /*
    @objc func publishBtnClick(){
        sendView.endEditing(true)
        let object = AVObject(className: "Posts")
        object["username"] = AVUser.current()?.username
        object["ava"] = AVUser.current()?.value(forKey: "ava") as! AVFile
        let uuid = NSUUID().uuidString
        object["puuid"] = "\(AVUser.current()?.username)\(uuid)"
        
        //判断titleTxt是否为空
        if sendView.titleTxt.text.isEmpty{
            object["title"] = ""
        }else{
            object["title"] = sendView.titleTxt.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        //生成照片数据
        let imageData = UIImageJPEGRepresentation(sendView.picImg.image!, 0.5)
        let imageFile = AVFile(name: "post.jpg", data: imageData!)
        object["pic"] = imageFile
        
        //发hashtag到云端
        let words:[String] = sendView.titleTxt.text.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
        for var word in words{
            //定义正则表达式
            let pattern = "#[^#]+"
            let regular = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let results = regular.matches(in: word, options: .reportProgress, range: NSMakeRange(0, word.count))
            
            //输出截取结果
            print("符合的结果有\(results.count)")
            for result in results{
                word = (word as NSString).substring(with: result.range)
            }
            if word.hasPrefix("#"){
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                word = word.trimmingCharacters(in: CharacterSet.symbols)
                
                let hashtagObj = AVObject(className: "Hashtags")
                hashtagObj["to"] = "\(AVUser.current()?.username!)\(uuid)"
                hashtagObj["by"] = AVUser.current()?.username!
                hashtagObj["hashtag"] = word.lowercased()
                hashtagObj["comment"] = sendView.titleTxt.text
                hashtagObj["isPost"] = true
                hashtagObj.saveInBackground({ (success:Bool, error:Error?) in
                    if success{
                        print("hashtag\(word)已被创建")
                    }else{
                        print(error?.localizedDescription)
                    }
                })
            }
        }
        
        //存储
        object.saveInBackground { (success:Bool, error:Error?) in
            if error == nil{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:"uploaded"), object: nil)
                self.popover.dismiss()
                self.dismiss(animated: true, completion: nil)
            }else{
                print("上传错误\(error?.localizedDescription)")
            }
        }
    }
 */
    @objc func saveBtnClick(){
        sendView.endEditing(true)
        
        UIImageWriteToSavedPhotosAlbum(sendView.picImg.image!, self,#selector(self.didSaveImageToAlbum(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    //完成存储方法
    @objc func didSaveImageToAlbum(image:UIImage,didFinishSavingWithError error:NSError?,contextInfo:AnyObject) {
        SVProgressHUD.setMinimumDismissTimeInterval(1.2)
        if error != nil {
            SVProgressHUD.showError(withStatus: "保存失败")
            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.black)
        } else {
            self.popover.dismiss()
            SVProgressHUD.showSuccess(withStatus: "保存成功")
            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.black)
        }
    }
    func initSomeParameters() {
        //初始化颜色参数，避免找不到对象
        if UserDefaults.standard.string(forKey: "defaultsColor") == nil {
            UserDefaults.standard.set("#DEF3FD", forKey: "defaultsColor")
        }
        //print("试试看默认参数：\(UserDefaults.standard.float(forKey: "sfsgfsgsg"))")
        if UserDefaults.standard.float(forKey: "depth") == 0.0 {
            UserDefaults.standard.set(Float(1.0), forKey: "depth")
        }
        if UserDefaults.standard.float(forKey: "size") == 0.0 {
            UserDefaults.standard.set(10.0,forKey: "size")
        }
    }
    func setupScene(){
        let scene = SCNScene()
        sceneView.scene = scene
        
        sceneView.debugOptions = []
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.antialiasingMode = .multisampling2X //激活抗锯齿模式
        
        //sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = false //我们自己来控制灯光
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Media.scnassets/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = 1
        
        let constraint = SCNLookAtConstraint(target: sceneView.scene.rootNode)
        let light = SCNLight()
        light.type = .directional
        light.castsShadow = true
        light.shadowRadius = 200
        light.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        light.shadowMode = .deferred
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(0.5,1,0.2)
        lightNode.constraints = [constraint]
        sceneView.scene.rootNode.addChildNode(lightNode)
        
        let light2 = SCNLight()
        light2.type = .ambient
        light2.intensity = 200
        let lightNode2 = SCNNode()
        lightNode2.light = light2
        lightNode2.constraints = [constraint]
        sceneView.scene.rootNode.addChildNode(lightNode2)
    }
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        //使HDR相机设置最逼真的环境照明和物理基础材料。
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    @IBAction func changeState(_ sender: UIButton) {
        if !isFSHidden{
            sender.setImage(UIImage(named: "方块隐藏"), for: UIControlState.normal)
            isFSHidden = true
        }else{
            sender.setImage(UIImage(named: "方块"), for: UIControlState.normal)
            isFSHidden = false
        }
        focusSquare.isHidden = isFSHidden
        UserDefaults.standard.set(isFSHidden, forKey: "isFSHidden")
    }
    @IBAction func takeSnapshot(_ sender: UIButton) {
        if sendView != nil{
            sendView.picImg.image = sceneView.snapshot()
            sendView.titleTxt.text = ""
            popover.show(sendView!, point: CGPoint(x: 752, y: 144))
            if online{
                sendView?.titleTxt.becomeFirstResponder()
            }
        }
    }
    @IBAction func cancelSnapshot(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    func alert(error:String,message:String){
        let alert = UIAlertController(title: error, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
    @objc func keyboardWillShow(_ notification:Notification){
        let rect = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]) as! NSValue
        keyboard = rect.cgRectValue
        
        UIView.animate(withDuration: 0.4) {
            self.inputTextAndBtn.frame.origin.y = self.view.frame.height - self.keyboard.height - 42
        }
    }
    @objc func keyboardWillHide(_ notification:Notification){
        UIView.animate(withDuration: 0.4) {
            self.inputTextAndBtn.frame.origin.y = self.view.frame.height - 42
            print("self.inputTextAndBtn.frame.origin.y:\(self.inputTextAndBtn)+isHidden:\(self.inputTextAndBtn.isHidden)")
        }
    }
    
    @IBAction func setColorBtn(_ sender: UIButton) {
        //弹出颜色选择器
        let colorSelectionController = EFColorSelectionViewController()
        let navCtrl = UINavigationController(rootViewController: colorSelectionController)
        navCtrl.navigationBar.backgroundColor = UIColor.white
        navCtrl.navigationBar.isTranslucent = false
        navCtrl.modalPresentationStyle = UIModalPresentationStyle.popover
        navCtrl.popoverPresentationController?.delegate = self
        navCtrl.popoverPresentationController?.sourceView = sender
        navCtrl.popoverPresentationController?.sourceRect = sender.bounds
        navCtrl.preferredContentSize = colorSelectionController.view.systemLayoutSizeFitting(
            UILayoutFittingCompressedSize
        )
        colorSelectionController.delegate = self
        colorSelectionController.color = UIColor.init(hexString: UserDefaults.standard.string(forKey: "defaultsColor")!)
        
        if UIUserInterfaceSizeClass.compact == self.traitCollection.horizontalSizeClass {
            let doneBtn: UIBarButtonItem = UIBarButtonItem(
                title: NSLocalizedString("Done", comment: ""),
                style: UIBarButtonItemStyle.done,
                target: self,
                action: nil
            )
            colorSelectionController.navigationItem.rightBarButtonItem = doneBtn
        }
        self.present(navCtrl, animated: true, completion: nil)
    }
    func colorViewController(colorViewCntroller: EFColorSelectionViewController, didChangeColor color: UIColor) {
        UserDefaults.standard.set(color.hexString(), forKey: "defaultsColor")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //保持屏幕常亮
        UIApplication.shared.isIdleTimerDisabled = true
        
        // 创建 session 配置（configuration）实例
        let configuration = ARWorldTrackingConfiguration()
        // 明确表示需要追踪水平面。设置后 scene 被检测到时就会调用 ARSCNViewDelegate 方法
        configuration.planeDetection = .horizontal
        // 运行 view 的 session
        sceneView.session.run(configuration, options: [.resetTracking,.removeExistingAnchors])
    }
    
    @IBAction func toggleHidden(_ sender: UISegmentedControl) {
        if isToggleTrue{
            sceneView.debugOptions = []
            sceneView.showsStatistics = false
            isToggleTrue = false
        }else{
            sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
            sceneView.showsStatistics = true
            isToggleTrue = true
        }
    }
    @IBAction func sendBtn(_ sender: Any) {
        var text = (inputText.text?.isEmpty)! ? "无文字":inputText.text!
        text = text.replacingOccurrences(of: "\\n", with: "\n")
        let fontSize:CGFloat = CGFloat(UserDefaults.standard.float(forKey: "size"))
        let textColor = UIColor.init(hexString: UserDefaults.standard.string(forKey: "defaultsColor")!)
        //从存储中读取
        
        let fontType = UserDefaults.standard.integer(forKey: "font")
        var fontTypeString:String
        switch fontType {
        case 1:
            fontTypeString = "Source Han Serif SC"
        case 2:
            fontTypeString = "WenQuanYi Zen Hei"
        case 3:
            fontTypeString = "郑庆科黄油体Regular"
        default:
            fontTypeString = "PingFang SC"
        }
        let textFont = UIFont(name: fontTypeString, size: fontSize)
        let textDepth = UserDefaults.standard.float(forKey: "depth")
        let textScn = ARText(text: text, font: textFont!, color: textColor, depth: CGFloat(textDepth)*(fontSize/10))
        print("CGFloat(textDepth)*(fontSize/10):\(CGFloat(textDepth)*(fontSize/10))")
        let textNode = TextNode(fsPosition: focusSquare.lastPosition!, scntext: textScn, sceneView: sceneView, scale: 1/100)
        textNodes.append(textNode)
        //print("添加了第\(textNodes.count)个节点")
        self.sceneView.scene.rootNode.addChildNode(textNode)
        
        //添加小方块，临时
        let size:CGFloat = 0.1
        
        let box = SCNBox(width: size, height: size, length: size, chamferRadius: 0.025)
        box.firstMaterial?.lightingModel = .physicallyBased
        box.firstMaterial?.specular.contents = UIColor.black
        box.firstMaterial?.diffuse.contents = UIColor.gray
        box.firstMaterial?.roughness.contents = UIImage(named: "Media.scnassets/scuffed-plastic-rough.png")
        box.firstMaterial?.metalness.contents = UIImage(named: "Media.scnassets/scuffed-plastic-metal.png")
        box.firstMaterial?.normal.contents = UIImage(named: "Media.scnassets/scuffed-plastic-normal.png")
        box.firstMaterial?.ambientOcclusion.contents = UIImage(named: "Media.scnassets/scuffed-plastic-ao.png")
        let node = SCNNode(geometry: box)
        let position = focusSquare.lastPosition!
        
        node.position = SCNVector3Make(position.x, position.y+Float(size/2), position.z)
        //self.sceneView.scene.rootNode.addChildNode(node)
        
        
        
        let floor = SCNFloor()
        floor.reflectivity = 0
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        floor.materials = [material]
        let floorNode:CreatObject
        floorNode = CreatObject()
        floorNode.geometry = floor
        floorNode.position = SCNVector3Make(focusSquare.lastPosition!.x, focusSquare.lastPosition!.y, focusSquare.lastPosition!.z)
        floorNodes.append(floorNode)
        sceneView.scene.rootNode.addChildNode(floorNode)
    }
    func updateFocusSquare() {
        // 除非sceen只是初始化，否则我们应该始终拥有一个有效的世界位置。
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 暂停会话
        sceneView.session.pause()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    // ARSCNViewDelegate的一系列方法
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.virtualObjectInteraction.updateObjectToCurrentTrackingPosition()
            self.updateFocusSquare()
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        self.viewAnchor = anchor
        //UI相关放在主线程里
        DispatchQueue.main.async {
            self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
            self.statusViewController.showMessage("检测到平面")
            self.inputTextAndBtn.frame.origin.y = self.view.frame.height
            self.inputTextAndBtn.isHidden = false
            UIView.animate(withDuration: 0.4) {
                self.inputTextAndBtn.frame.origin.y = self.view.frame.height-42
            }
        }
        //加上这个方法让平面更稳定
        updateQueue.async {
            for singleNode in self.textNodes{
                singleNode.adjustOntoPlaneAnchor(anchor,using:node)
            }
            for singleNode in self.floorNodes{
                singleNode.adjustOntoPlaneAnchor(anchor,using:node)
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 查看此平面当前是否正在渲染
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        //加上这个方法让平面更稳定
        updateQueue.async {
            for singleNode in self.textNodes{
                singleNode.adjustOntoPlaneAnchor(anchor,using:node)
            }
            for singleNode in self.floorNodes{
                singleNode.adjustOntoPlaneAnchor(anchor,using:node)
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    }
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
            if online{
                cancelBtn.isHidden = false
            }
        }
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        // 向用户显示错误消息
    }
    func sessionWasInterrupted(_ session: ARSession) {
        // 通知用户会话已被中断，例如，通过呈现一个覆盖层
        statusViewController.showMessage("""
        SESSION INTERRUPTED
        中断结束后，会话将重置。
        """, autoHide: false)
    }
    func sessionInterruptionEnded(_ session: ARSession) {
        statusViewController.showMessage("欢迎回来")
    }
}

