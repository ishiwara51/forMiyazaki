//
//  AppDelegate.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/13.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        sleep(2)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        var initialViewController = storyboard.instantiateViewController(withIdentifier: "first")
        
        if let userId = AppDelegate().getKeyChain(key: "userId") {
            print(userId)
            initialViewController = storyboard.instantiateViewController(withIdentifier: "option")
        }
        
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func httpRequest(route:String, postBodyStr:String, calledBy:UIViewController? = nil, callTag:Int = 0) -> String? {
        let url = URL(string: "http://52.20.57.114:5000/" + route)
        var request = URLRequest(url: url!)
        var returnstr = ""
        // POSTを指定
        request.httpMethod = "POST"
        // POSTするデータをBodyとして設定
        request.httpBody = postBodyStr.data(using: .utf8)
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                // HTTPヘッダの取得
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                // HTTPステータスコード
                print("statusCode: \(response.statusCode)")
                print(String(data: data, encoding: .utf8) ?? "")
                returnstr = String(data: data, encoding: .utf8) ?? ""
                if calledBy != nil{
                    switch callTag{
                    case 0:
                        let vc = calledBy as! PlayFullKeyboardViewController
                        vc.getAIDic(json: returnstr)
                    case 1:
                        let vc = calledBy as! SummarySelectViewController
                        vc.getTransferID(id: returnstr)
                    case 2:
                        let vc = calledBy as! FirstLoginViewController
                        vc.getTransferResult(result: returnstr)
                    default:
                        break
                    }
                }
            }
            }.resume()
        print(returnstr)
        return(returnstr)
    }
    
    func saveKeyChain(str: String, key:String) {
        let data = str.data(using: .utf8)
        guard let _data = data else { return }
        
        let dic: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                  kSecAttrGeneric as String: key,
                                  kSecAttrAccount as String: "account",
                                  kSecValueData as String: _data]
        
        var itemAddStatus: OSStatus?
        // 保存データが存在するかの確認
        let matchingStatus = SecItemCopyMatching(dic as CFDictionary, nil)
        if matchingStatus == errSecItemNotFound {
            // 保存
            itemAddStatus = SecItemAdd(dic as CFDictionary, nil)
        } else if matchingStatus == errSecSuccess {
            // 更新
            itemAddStatus = SecItemUpdate(dic as CFDictionary, [kSecValueData as String: _data] as CFDictionary)
        } else {
            print("保存失敗")
        }
        // 保存・更新ステータス確認
        if itemAddStatus == errSecSuccess {
            print("正常終了")
        } else {
            print("保存失敗")
        }
    }
    
    func getKeyChain(key: String) -> String? {
        let dic: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                  kSecAttrGeneric as String: key,
                                  kSecReturnData as String: kCFBooleanTrue]
        
        var data: AnyObject?
        let matchingStatus = withUnsafeMutablePointer(to: &data){
            SecItemCopyMatching(dic as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if matchingStatus == errSecSuccess {
            print("取得成功")
            if let getData = data as? Data,
                let getStr = String(data: getData, encoding: .utf8) {
                return getStr
            }
            print("取得失敗: Dataが不正")
            return nil
        } else {
            print("取得失敗")
            return nil
        }
    }


}

