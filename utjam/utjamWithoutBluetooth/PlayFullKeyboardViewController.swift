//
//  ViewController.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/13.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit
import AVFoundation
import MultipeerConnectivity

class PlayFullKeyboardViewController: UIViewController{

    var audioPlayers:[AVAudioPlayer] = []
    var bgmPlayer: AVAudioPlayer! = nil
    var bgmTag:String? //passed by MusicSelectView.
    var bluetoothTag:String? //passed by MusicSelectView.
    var bpm:Float = 0.0
    var beat:Float = 0.0
    var numberOfBar:Int = 0
    var barNow:Int = 0
    var pathUtilityPlist:Optional<Any> = nil
    var bgmNSDictPre:NSDictionary = [:]
    var bgmNSDict:NSDictionary = [:]
    var scalesNSDict:NSDictionary = [:]
    var notesNSArray:NSArray = []
    var uiParametersNSDict:NSDictionary = [:]
    var keyboardButtonList:[UIButton] = []
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    @IBOutlet weak var C0: UIButton!
    @IBOutlet weak var D0: UIButton!
    @IBOutlet weak var E0: UIButton!
    @IBOutlet weak var F0: UIButton!
    @IBOutlet weak var G0: UIButton!
    @IBOutlet weak var A1: UIButton!
    @IBOutlet weak var B1: UIButton!
    @IBOutlet weak var Cs0: UIButton!
    @IBOutlet weak var Ds0: UIButton!
    @IBOutlet weak var Fs0: UIButton!
    @IBOutlet weak var Gs0: UIButton!
    @IBOutlet weak var As1: UIButton!
    @IBOutlet weak var C1: UIButton!
    @IBOutlet weak var Cs1: UIButton!
    @IBOutlet weak var D1: UIButton!
    @IBOutlet weak var Ds1: UIButton!
    @IBOutlet weak var E1: UIButton!
    @IBOutlet weak var F1: UIButton!
    @IBOutlet weak var Fs1: UIButton!
    @IBOutlet weak var Gs1: UIButton!
    @IBOutlet weak var G1: UIButton!
    @IBOutlet weak var A2: UIButton!
    @IBOutlet weak var As2: UIButton!
    @IBOutlet weak var B2: UIButton!
    @IBOutlet weak var C2: UIButton!
    @IBOutlet weak var Cs2: UIButton!
    @IBOutlet weak var D2: UIButton!
    @IBOutlet weak var Ds2: UIButton!
    @IBOutlet weak var E2: UIButton!
    @IBOutlet weak var F2: UIButton!
    @IBOutlet weak var Fs2: UIButton!
    @IBOutlet weak var G2: UIButton!
    @IBOutlet weak var Gs2: UIButton!
    @IBOutlet weak var A3: UIButton!
    @IBOutlet weak var As3: UIButton!
    @IBOutlet weak var B3: UIButton!
    @IBOutlet weak var C3: UIButton!
    @IBOutlet weak var Cs3: UIButton!
    @IBOutlet weak var D3: UIButton!
    @IBOutlet weak var Ds3: UIButton!
    @IBOutlet weak var E3: UIButton!
    @IBOutlet weak var F3: UIButton!
    @IBOutlet weak var Fs3: UIButton!
    @IBOutlet weak var G3: UIButton!
    @IBOutlet weak var Gs3: UIButton!
    @IBOutlet weak var A4: UIButton!
    @IBOutlet weak var As4: UIButton!
    @IBOutlet weak var B4: UIButton!
    @IBOutlet weak var C4: UIButton!
    @IBOutlet weak var Cs4: UIButton!
    @IBOutlet weak var D4: UIButton!
    @IBOutlet weak var Ds4: UIButton!
    @IBOutlet weak var E4: UIButton!
    @IBOutlet weak var F4: UIButton!
    @IBOutlet weak var Fs4: UIButton!
    @IBOutlet weak var G4: UIButton!
    @IBOutlet weak var Gs4: UIButton!
    @IBOutlet weak var A5: UIButton!
    @IBOutlet weak var As5: UIButton!
    @IBOutlet weak var B5: UIButton!
    @IBOutlet weak var C5: UIButton!
    @IBOutlet weak var Cs5: UIButton!
    @IBOutlet weak var D5: UIButton!
    @IBOutlet weak var Ds5: UIButton!
    @IBOutlet weak var E5: UIButton!
    @IBOutlet weak var F5: UIButton!
    @IBOutlet weak var Fs5: UIButton!
    @IBOutlet weak var G5: UIButton!
    @IBOutlet weak var Gs5: UIButton!
    @IBOutlet weak var A6: UIButton!
    @IBOutlet weak var As6: UIButton!
    @IBOutlet weak var B6: UIButton!
    @IBOutlet weak var C6: UIButton!
    @IBOutlet weak var Cs6: UIButton!
    @IBOutlet weak var D6: UIButton!
    @IBOutlet weak var Ds6: UIButton!
    @IBOutlet weak var E6: UIButton!
    @IBOutlet weak var F6: UIButton!
    @IBOutlet weak var Fs6: UIButton!
    @IBOutlet weak var G6: UIButton!
    @IBOutlet weak var Gs6: UIButton!
    @IBOutlet weak var A7: UIButton!
    @IBOutlet weak var As7: UIButton!
    @IBOutlet weak var B7: UIButton!
    
    
    @IBAction func buttonTouchDown(_ sender: UIButton) {
    /* call keyPushed() to play a sound file. */
        keyPushed(senderTag: sender.tag)
    }
    
    @IBAction func buttonTouchUpInside(_ sender: UIButton) {
        /* call keyPushed() to stop a sound file. */
        keyReleased(senderTag: sender.tag)
    }
    
    func keyPushed(senderTag:Int){
    /* play a sound file and emphasize the border of button to show user its activated status  */
        print(senderTag)
        audioPlayers[senderTag].currentTime = 0
        audioPlayers[senderTag].play()
        keyboardButtonList[senderTag].layer.borderWidth  = 3
    }
    
    func keyReleased(senderTag:Int){
    /* stop the sound file and restore the border of button to show user its deactivated status  */
        print(senderTag)
        //audioPlayers[senderTag].stop() // Commented out now because this makes some noize.
        keyboardButtonList[senderTag].layer.borderWidth  = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Line below tends to center the keyboard horizontally at the beggining, but does not work now. Please fix.
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: scrollView.contentSize.width/(-2), bottom: 0, right: 0)
        setVariables() //Initialize the member variables.
        prepareSound() // Set the sound files activated.
        startBGM()  // Start the bgm file.
        
        /* Start timer to controll the change of scales along the bars.
           relodeSoundKey will be called when the bar changes. */
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(beat*(60/bpm)), repeats: true, block: { (timer) in
            if self.barNow == self.numberOfBar{
                timer.invalidate()
                print("finished!")
                Thread.sleep(forTimeInterval: 2.0) // Just I thought users would feel uncomfortable when the view is shut down suddenly after the bgm ended...
                self.terminateViewController()
            }else{
                self.barNow += 1
                self.relodeSoundKey()
            }
        })
    }
    
    func setVariables(){
        self.audioPlayers = []
        self.pathUtilityPlist = Bundle.main.path(forResource: "Utility", ofType: "plist")
        self.bgmNSDictPre = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["bgmDict"] as! NSDictionary
        self.bgmNSDict = self.bgmNSDictPre.object(forKey:bgmTag!) as! NSDictionary
        self.scalesNSDict = (NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["scalesDict"] as! NSDictionary)["full"] as! NSDictionary
        self.notesNSArray = (NSDictionary(contentsOfFile: pathUtilityPlist! as! String)!["soundsList"] as! NSArray)
        self.uiParametersNSDict = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["uiParametersDict"] as! NSDictionary
        self.bpm = bgmNSDict.object(forKey:"bpm") as! Float
        self.beat = bgmNSDict.object(forKey:"beat") as! Float
        self.numberOfBar = bgmNSDict.object(forKey:"numberOfBar") as! Int
        self.barNow = 0
        self.keyboardButtonList = [
        UIButton(), UIButton(), UIButton(), C0, Cs0, D0, Ds0, E0, F0, Fs0, G0, Gs0,
        A1, As1, B1, C1, Cs1, D1, Ds1, E1, F1, Fs1, G1, Gs1,
        A2, As2, B2, C2, Cs2, D2, Ds2, E2, F2, Fs2, G2, Gs2,
        A3, As3, B3, C3, Cs3, D3, Ds3, E3, F3, Fs3, G3, Gs3,
        A4, As4, B4, C4, Cs4, D4, Ds4, E4, F4, Fs4, G4, Gs4,
        A5, As5, B5, C5, Cs5, D5, Ds5, E5, F5, Fs5, G5, Gs5,
        A6, As6, B6, C6, Cs6, D6, Ds6, E6, F6, Fs6, G6, Gs6,
        A7, As7, B7, UIButton()]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    func prepareSound(){
    /* Activate the sound files for immediate play when the user push keys.
        When a key button is pushed by user, the sound with index of the key's tab will be played. */
    
        var audioPlayer: AVAudioPlayer! = nil
        
        for keyNSTaggedPointerString in notesNSArray{
            let key = keyNSTaggedPointerString as! String
            let pianoSoundsNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "sound/\(key)", ofType: "mp3")!)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: pianoSoundsNSURL as URL, fileTypeHint:nil)
            } catch {
                print(pianoSoundsNSURL)
                print("SoundのAVAudioPlayerインスタンス作成でエラー")
            }
            // 再生準備
            audioPlayer.prepareToPlay()
            audioPlayers.append(audioPlayer)
        }
    }
    
    func startBGM(){
    /* Start BGM */
        let bgmFileName = bgmNSDict.object(forKey:String("title")) as! String
        let bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmFileName))", ofType: "mp3")!)
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: bgmNSURL as URL, fileTypeHint:nil)
        } catch {
            print("BGMのAVAudioPlayerインスタンス作成でエラー")
        }
        bgmPlayer.currentTime = 0
        bgmPlayer.prepareToPlay()
        bgmPlayer.play()
    }
        
    func relodeSoundKey(){
    /* Relode the scale when the ordered scale is changed.
       The color of every key in the scale would be colored so that users can distinguish it.
         */
        for keyboardButton in keyboardButtonList{
            switch keyboardButton.tag % 12{
            case 0,2,3,5,7,8,10:
                keyboardButton.layer.backgroundColor = UIColor(red:255, green: 255, blue: 255, alpha: 1).cgColor
            default:
                keyboardButton.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
            }
        }
        
        let scaleNow:String = (bgmNSDict.object(forKey:"scalesList") as! NSArray)[barNow-1] as! String
        let soundNSArrayInScaleNow: NSArray = scalesNSDict.object(forKey:scaleNow) as! NSArray
        for soundKeyNSString in soundNSArrayInScaleNow{
            keyboardButtonList[(soundKeyNSString as! Int)].layer.backgroundColor = UIColor(red:0, green: 255, blue: 255, alpha: 1).cgColor
        }
    }
    func terminateViewController(){
    /* Called when the bgm finished. */
        self.presentingViewController?.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    deinit{
        print("A deinit")
    }
}
