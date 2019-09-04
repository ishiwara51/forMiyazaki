//
//  TutorialSummaryViewController.swift
//  utjamBluetooth
//
//  Created by Macky on 2019/08/17.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit
import WebKit
import NendAd

class TutorialSummaryViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    var path: String?
    var backFromAd = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let htmlData = Bundle.main.path(forResource: path, ofType: "html")!
        let localHTMLUrl = URL(fileURLWithPath: htmlData, isDirectory: false)
        webView.loadFileURL(localHTMLUrl, allowingReadAccessTo: localHTMLUrl)
        //webView.load(req)
        
        activity.startAnimating()
        webView.navigationDelegate = self
        activity.hidesWhenStopped = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if backFromAd{
            (self.presentingViewController as? PlayFullKeyboardViewController)?.backFromAd = true
            self.dismiss(animated: false)
        }
    }
    
    @IBAction func finishTutorial() {
        //self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        guard let secondVc = self.presentingViewController as? PlayFullKeyboardViewController else {
            dismiss(animated: true, completion: nil)
            return
        }
        presentAd(currentVC: self)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activity.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activity.stopAnimating()
    }
}

class AdViewController: UIViewController {
    private var client: NADNativeClient!
    
    @IBOutlet weak var guideView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.client = NADNativeClient(spotId: "969739", apiKey: "f51280d055b476f53bf8a15c760b34dc4fb60da5")
        self.client.load() { (ad, error) in
            if let nativeAd = ad {
                //success
                let nativeAd: NADNative = nativeAd
                let adView = Bundle.main.loadNibNamed("NativeAdView", owner: self, options: nil)!.first! as? YourNativeAdView
                adView?.frame.size = self.guideView.frame.size
                nativeAd.intoView(adView, advertisingExplicitly: .PR)
                self.guideView.addSubview(adView!)
            }else{
                print("error: \(String(describing: error))")
            }
        }
        /*let interval = 30.0
        self.client.enableAutoReload(withInterval: interval, completionBlock: { (ad, error) in
            if let nativeAd = ad {
                // 成功
            } else {
                print("error: \(String(describing: error))")
            }
        })*/
    }
    
    @IBAction func closeView() {
        (self.presentingViewController as? PlayFullKeyboardViewController)?.backFromAd = true
        (self.presentingViewController as? TutorialSummaryViewController)?.backFromAd = true
        self.dismiss(animated: true, completion: nil)
    }
}

class YourNativeAdView: UIView, NADNativeViewRendering {
    
    @IBOutlet private weak var nativeAdPrTextLabel: UILabel!
    @IBOutlet private weak var nativeAdShortTextLabel: UILabel!
    @IBOutlet private weak var nativeAdLongTextLabel: UILabel!
    @IBOutlet private weak var nativeAdPromotionNameLabel: UILabel!
    @IBOutlet private weak var nativeAdPromotionUrlLabel: UILabel!
    @IBOutlet private weak var nativeAdActionButtonTextLabel: UILabel!
    @IBOutlet private weak var nativeAdImageView: UIImageView!
    @IBOutlet private weak var nativeAdLogoImageView: UIImageView!
    
    // MARK: - NADNativeViewRendering
    
    func prTextLabel() -> UILabel! {
        return self.nativeAdPrTextLabel
    }
    
    func shortTextLabel() -> UILabel! {
        return self.nativeAdShortTextLabel
    }
    
    func longTextLabel() -> UILabel! {
        return self.nativeAdLongTextLabel
    }
    
    func promotionNameLabel() -> UILabel! {
        return self.nativeAdPromotionNameLabel
    }
    
    func promotionUrlLabel() -> UILabel! {
        return self.nativeAdPromotionUrlLabel
    }
    
    func actionButtonTextLabel() -> UILabel! {
        return self.nativeAdActionButtonTextLabel
    }
    
    func adImageView() -> UIImageView! {
        return self.nativeAdImageView
    }
    
    func nadLogoImageView() -> UIImageView! {
        return self.nativeAdLogoImageView
    }
    
}
