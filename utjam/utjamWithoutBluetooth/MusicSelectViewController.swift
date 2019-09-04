//
//  MusicSelectViewController.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/15.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit

class MusicSelectViewController: UIViewController {
    var bgmTag:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonTapped(sender : UIButton) {
        bgmTag = "\(sender.tag)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSingleMultiSelectViewController") {
            let vc: SingleMultiSelectViewController = (segue.destination as? SingleMultiSelectViewController)!
            // Send button.tag to bgmTag in next viewController.
            vc.bgmTag = self.bgmTag
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
