//
//  MusicSelectViewController.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/15.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit

class KeyboardTypeSelectViewController: UIViewController {
    var bgmTag:String?
    var bluetoothTag:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonFullKeyboardTapped(sender : UIButton) {
    }
    @IBAction func buttonScalePadTapped(sender : UIButton) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toPlayFullKeyboardViewController") {
            let vc: PlayFullKeyboardViewController = (segue.destination as? PlayFullKeyboardViewController)!
            // Send button.tag to bgmTag in next viewController.
            vc.bgmTag = self.bgmTag
            vc.bluetoothTag = self.bluetoothTag
        }
        if (segue.identifier == "toPlayScalePadViewController") {
            let vc: PlayScalePadViewController = (segue.destination as? PlayScalePadViewController)!
            // Send button.tag to bgmTag in next viewController.
            vc.bgmTag = self.bgmTag
            vc.bluetoothTag = self.bluetoothTag
        }
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
