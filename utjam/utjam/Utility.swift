//
//  Util.swift
//  utjamBluetooth
//
//  Created by 加納大地 on 2019/08/27.
//  Copyright © 2019 加納大地. All rights reserved.
//

import Foundation
import Reachability

final class Network {
    
    static func isOnline() -> Bool {
        guard let reachability = Reachability() else { return false }
        return reachability.connection != .none
    }
    
}

func presentAd(currentVC:UIViewController) {
    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let second = storyboard.instantiateViewController(withIdentifier: "ad")
    currentVC.present(second, animated: true)
}
