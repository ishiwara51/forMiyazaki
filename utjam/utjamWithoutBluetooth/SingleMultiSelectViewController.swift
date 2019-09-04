//
//  MusicSelectViewController.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/15.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit

class SingleMultiSelectViewController: UIViewController {
    var bgmTag:String?
    var bluetoothTag:String = ""
    
    override func viewDidLoad() { //これも二回呼ばれてる
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonSingleTapped(sender : UIButton) {
        bluetoothTag = "\(sender.tag)"
    }
    @IBAction func buttonTwoPlayersPadTapped(sender : UIButton) {
        bluetoothTag = "\(sender.tag)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc: KeyboardTypeSelectViewController = (segue.destination as? KeyboardTypeSelectViewController)!
        // Send bgmTag and bluetoothTag to next ViewController
        vc.bgmTag = self.bgmTag
        vc.bluetoothTag = self.bluetoothTag
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
