//
//  FontStyleVC.swift
//  3DARKit初体验
//
//  Created by 徐炜楠 on 2017/11/25.
//  Copyright © 2017年 徐炜楠. All rights reserved.
//

import UIKit

class FontStyleVC: UIViewController {
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var fontLabel: UILabel!
    @IBOutlet weak var materialLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var depthSlider: UISlider!
    @IBOutlet weak var fontSeg: UISegmentedControl!
    @IBOutlet weak var materialSeg: UISegmentedControl!
    @IBOutlet weak var sizeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSomeParameters()
        // Do any additional setup after loading the view.
    }
    func initSomeParameters(){
        depthSlider.setValue(UserDefaults.standard.float(forKey: "depth"), animated: false)
        fontSeg.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "font")
        sizeSlider.setValue(UserDefaults.standard.float(forKey: "size"), animated: false)
    }
    
    @IBAction func depthSliderValueChange(_ sender: UISlider) {
        depthLabel.text = String(sender.value)
    }
    //为了节省性能，只在手势结束时存储数据
    @IBAction func depthSliderTouchUpInside(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "depth")
        depthLabel.text = "文字深度"
    }
    @IBAction func depthSliderTouchUpOutside(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "depth")
        depthLabel.text = "文字深度"
    }
    
    @IBAction func sizeSliderValueChange(_ sender: UISlider) {
        sizeLabel.text = String(sender.value)
    }
    @IBAction func sizeSliderTouchUpInside(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "size")
        sizeLabel.text = "文字大小"
    }
    @IBAction func sizeSliderTouchUpOutside(_ sender: UISlider) {
        UserDefaults.standard.set(sender.value, forKey: "size")
        sizeLabel.text = "文字大小"
    }
    
    @IBAction func fontSegValueChange(_ sender: UISegmentedControl) {
        //0-默认 1-楷书 2-隶书 3-行书
        let value = sender.selectedSegmentIndex
        UserDefaults.standard.set(value, forKey: "font")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
