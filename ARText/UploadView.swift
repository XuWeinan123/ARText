//
//  UploadView.swift
//  Instagram
//
//  Created by 徐炜楠 on 11/12/2017.
//  Copyright © 2017 xuweinan. All rights reserved.
//

import UIKit

class UploadView: UIView,UITextViewDelegate {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    @IBOutlet weak var picImg: UIImageView!
    @IBOutlet weak var titleTxt: UITextView!
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var removeBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    class func newInstance(frame:CGRect) -> UploadView?{
        let nibView = Bundle.main.loadNibNamed("UploadView", owner: nil, options: nil)
        if let view = nibView?.first as? UploadView{
            //view.frame = frame
            view.titleTxt.delegate = view
            return view
        }
        return nil
    }
    func textViewDidChange(_ textView: UITextView) {
        print("文字改变了！\(textView.text!)")
        let text = textView.text!
        if(!text.isEmpty){
            self.publishBtn.isEnabled = true
        }else{
            self.publishBtn.isEnabled = false
        }
    }
    /// 隐藏发表按钮，显示保存按钮，隐藏简介文字
    func offlineMode(){
        self.publishBtn.isHidden = true
        self.saveBtn.isHidden = false
        self.titleTxt.isHidden = true
    }
}
