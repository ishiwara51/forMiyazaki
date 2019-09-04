//
//  ViewController.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/13.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit
import AVFoundation

class PlayFlatPadViewController: UIViewController, AVAudioPlayerDelegate {
    
    @IBOutlet weak var connectionsLabel : UILabel!
    @IBOutlet weak var stackView : UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    // declare the variables to be initialized in init()
    
    var kanPlayer:AVAudioPlayer?
    var audioPlayers:[AVAudioPlayer] = [] // keyboard sound players
    var bgmPlayers: [AVAudioPlayer]! = [] // bgm players
    var bgmTag:String? //passed by MusicSelectView.
    var chorusNumber:Int? //passed by MusicSelectView.
    //var bluetoothTag:String? //passed by MusicSelectView.
    var pathUtilityPlist:Optional<Any> = nil
    var bgmNSDict:NSDictionary = [:]
    var bpm:Float = 0.0
    var beat:Float = 0.0
    var numberOfBar:Int = 0 // bar count per chorus
    var barNow:Int = 0 // what bar are we on
    var introBars:Int = 0
    var chorusNumberNow:Int = 0
    var scalesNSDict:NSDictionary = [:]
    var scalesDict = [String:[Int]]()
    var scaleBaseName = ""
    var notesNSArray:NSArray = []
    var uiParametersNSDict:NSDictionary = [:]
    var keyboardButtonList:[UIView] = []
    var pushedKeys:[Int] = [] // UIView tag playing sound now
    var kanTimer:Timer = Timer()
    var playRecord:Dictionary<Double, Array<Any>> = Dictionary() //フリープレイ中の演奏データが記録される
    var timeNow = 0.0 // timer for recording player's play
    var touchingKeyboards:[Int] = [] // UIView tag pushed now
    let KEYBOARD_HEIGHT = Double(75*15)
    let QUANTIZE:Double = 1/324
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        // Do any additional setup after loading the view.
        setVariables() //Initialize the member variables.
        prepareScales() // Register the scales used in the number.
        prepareSound() // Set the sound files activated.
        startFreePlay()
        self.scrollView.backgroundColor = UIColor.red
    }
    
    func setVariables(){
        self.pathUtilityPlist = Bundle.main.path(forResource: "Utility", ofType: "plist")
        let bgmNSDictPre: NSDictionary = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["bgmDict"] as! NSDictionary
        self.bgmNSDict = bgmNSDictPre.object(forKey:bgmTag!) as! NSDictionary
        self.bpm = bgmNSDict.object(forKey:"bpm") as! Float
        self.beat = bgmNSDict.object(forKey:"beat") as! Float
        self.numberOfBar = bgmNSDict.object(forKey:"numberOfBar") as! Int
        self.barNow = 0
        self.introBars = 0
        self.chorusNumberNow = 0
        self.scalesNSDict = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["scalesDict"] as! NSDictionary
        self.scalesDict = [:]
        self.scaleBaseName = bgmNSDict["scaleBaseName"] as! String
        self.notesNSArray = (NSDictionary(contentsOfFile: pathUtilityPlist! as! String)!["soundsList"] as! NSArray)
        self.uiParametersNSDict = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["uiParametersDict"] as! NSDictionary
        
        for j in 0..<15{ //vertical
            for i in 0..<10 { // horizontal
                self.keyboardButtonList.append(makeKeyboard(i: i, j: j))
            }
        }
        for i in keyboardButtonList {
            self.stackView.addSubview(i)
        }
        self.keyboardButtonList = [UIView(), UIView(), UIView()] + self.keyboardButtonList + [UIView](repeating: UIView(), count: 80)
        self.stackView.frame = CGRect(x:stackView.frame.origin.x , y: stackView.frame.origin.y, width: stackView.frame.width, height: CGFloat(KEYBOARD_HEIGHT))
    }
    
    func makeKeyboard(i: Int, j:Int) -> UIView {
        let filePath = Bundle.main.path(forResource: "Utility", ofType: "plist")!
        let plist = NSDictionary(contentsOfFile: filePath)
        let soundsList = plist!["soundsList"] as! [String]
        
        let btn = UIView()
        btn.tag = (15-j)*5+i+3
        btn.frame = CGRect(x: Double(i)*55.5, y: Double(j)*75.0, width: 55.5, height: 75)
        btn.backgroundColor = UIColor.white
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 1
        
        let lb = UILabel()
        lb.text = soundsList[btn.tag]
        lb.sizeToFit()
        lb.center = CGPoint(x: btn.frame.width/2, y: btn.frame.height/2)
        btn.addSubview(lb)
        
        return btn
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        self.scrollView.setContentOffset(CGPoint(x: 0, y: (KEYBOARD_HEIGHT-Double(self.scrollView.frame.height))*Double(0.5)), animated: false)
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        scrollView.contentOffset = CGPoint(x: 0, y: (KEYBOARD_HEIGHT-Double(self.scrollView.frame.height))*Double(1.0-sender.value))
    }
    
    @IBAction func pauseTapped() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let popupView = storyBoard.instantiateViewController(withIdentifier: "pause") as! PauseViewController
        popupView.parentTag = 1
        popupView.modalPresentationStyle = .overFullScreen
        popupView.modalTransitionStyle = .crossDissolve
        self.present(popupView, animated: true, completion: nil)
    }
    
    //MARK: Prepare Sounds
    
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
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.tag = audioPlayers.count
            audioPlayers.append(audioPlayer)
        }
        let pianoSoundsNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "sound/Count", ofType: "mp3")!)
        do {
            kanPlayer = try AVAudioPlayer(contentsOf: pianoSoundsNSURL as URL, fileTypeHint:nil)
        } catch {
            print(pianoSoundsNSURL)
            print("SoundのAVAudioPlayerインスタンス作成でエラー")
        }
        // 再生準備
        kanPlayer!.prepareToPlay()
    }
    
    func prepareBGM(){
        /* Start BGM */
        bgmPlayers = []
        
        let bgmFileName = bgmNSDict.object(forKey:String("title")) as! String
        var bgmPlayer: AVAudioPlayer! = nil
        
        for i in 1...chorusNumber!{
            let rondomisedChorusNumber = Int.random(in: 1..<5)
            var bgmNSURL:NSURL?
            if i != chorusNumber{
                bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmFileName))/chorus\(rondomisedChorusNumber)", ofType: "mp3")!)
            }else{
                bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmFileName))/last", ofType: "mp3")!)
            }
            // 臨時で"bgm/isntSheLovely/chorus1"にしてます
            //let bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/isntSheLovely/chorus1", ofType: "mp3")!)
            do {
                bgmPlayer = try AVAudioPlayer(contentsOf: bgmNSURL! as URL, fileTypeHint:nil)
            } catch {
                print("BGMのAVAudioPlayerインスタンス作成でエラー")
            }
            bgmPlayer.currentTime = 0
            bgmPlayer.prepareToPlay()
            print("bgm/\(String(describing: bgmFileName))/chorus\(rondomisedChorusNumber)")
            bgmPlayers.append(bgmPlayer)
        }
    }
    
    func prepareScales(){
        for scaleNameNSString in (bgmNSDict.object(forKey:"scalesList") as! NSArray){
            let scaleName = scaleNameNSString as! String
            if (Array(scalesDict.keys)).firstIndex(of: scaleName) == nil{
                setScalesDictForScaleName(scaleName: scaleName)
            }else{
                continue
            }
        }
        let scaleBaseName = bgmNSDict.object(forKey:"scaleBaseName") as! String
        if Array(scalesDict.keys).firstIndex(of: scaleBaseName) == nil{
            setScalesDictForScaleName(scaleName: scaleBaseName)
        }
    }
    
    func setScalesDictForScaleName(scaleName:String) {
        let notesInScale = (scalesNSDict.object(forKey:scaleName) as! NSArray) as! [Int]
        scalesDict[scaleName] = []
        for i in 0...12{
            scalesDict[scaleName] = scalesDict[scaleName]! + notesInScale.map{$0 + 12*i}
        }
    }
    
    func reloadSoundKey(){
        for keyboardButton in keyboardButtonList{
            keyboardButton.layer.backgroundColor = UIColor(red:255, green: 255, blue: 255, alpha: 1).cgColor
        }
        /* Reload the scale when the ordered scale is changed.
         The color of every key in the scale would be colored so that users can distinguish it.
         */
        let scaleNow:String = (bgmNSDict.object(forKey:"scalesList") as! NSArray)[(barNow-1)%self.numberOfBar] as! String
        for noteKey in scalesDict[scaleNow]!{
            keyboardButtonList[noteKey].layer.backgroundColor = UIColor(red:0, green: 255, blue: 255, alpha: 1).cgColor
        }
        for noteKey in scalesDict[scaleBaseName]!{
            keyboardButtonList[noteKey].layer.backgroundColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1).cgColor
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        pushChanged(senderTag: player.tag!, add: false)
        audioPlayers[player.tag!].prepareToPlay()
    }
    
    func terminateViewController() {
        for i in bgmPlayers {
            i.stop()
        }
        kanTimer.invalidate()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: self.stackView)
            let pointInView = touch.location(in: self.view)
            print("\(pointInView), \(self.scrollView.frame), \(self.scrollView.frame.contains(pointInView))")
            if self.scrollView.frame.contains(pointInView) == true {
                let hitView = self.stackView.hitTest(point, with: event)
                if hitView != nil {
                    self.pushChanged(senderTag: hitView!.tag, add: true)
                    
                    self.keyPushed(senderTag: hitView!.tag, userPushed: true)
                    self.keyboardTouchStateChanged(senderTag: hitView!.tag, add: true)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        var touchedKeys:[Int] = []
        for touch in touches {
            let point = touch.location(in: self.stackView)
            let pointInView = touch.location(in: self.view)
            if self.scrollView.frame.contains(pointInView) == true {
                let hitView = self.stackView.hitTest(point, with: event)
                if (hitView != nil) {
                    touchedKeys.append(hitView!.tag)
                    if pushedKeys.firstIndex(of: hitView!.tag) == nil || touchingKeyboards.firstIndex(of: hitView!.tag) == nil {
                        keyPushed(senderTag: hitView!.tag, userPushed: true)
                    }
                    pushChanged(senderTag: hitView!.tag, add: true)
                }
            }
        }
        touchingKeyboards = touchedKeys
        for i in keyboardButtonList {
            if touchingKeyboards.firstIndex(of: i.tag) == nil {
                i.layer.borderWidth = 1
            }else{
                i.layer.borderWidth = 3
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: self.stackView)
            let hitView = self.stackView.hitTest(point, with: event)
            if (hitView != nil) {
                pushChanged(senderTag: hitView!.tag, add: false)
                keyReleased(senderTag: hitView!.tag)
                keyboardTouchStateChanged(senderTag: hitView!.tag, add: false)
            }
        }
    }
    
    func pushChanged(senderTag:Int, add:Bool) {
        if add {
            if pushedKeys.firstIndex(of: senderTag) == nil {
                pushedKeys.append(senderTag)
            }
        }else if pushedKeys.firstIndex(of: senderTag) != nil {
            pushedKeys.remove(at: pushedKeys.firstIndex(of: senderTag)!)
            keyboardButtonList[senderTag].layer.borderWidth  = 1
        }
    }
    
    func keyPushed(senderTag:Int, userPushed:Bool = false){
        /* play a sound file and emphasize the border of button to show user its activated status  */
        keyboardButtonList[senderTag].layer.borderWidth  = 3
        DispatchQueue.global().async {
            self.audioPlayers[senderTag].currentTime = 0
            self.audioPlayers[senderTag].play()
            
            if userPushed {
                //let fromStartDate:Double = Date.timeIntervalSince(startTime)
                if self.playRecord[self.timeNow] != nil {
                    self.playRecord[self.timeNow]?.append(senderTag)
                }else {
                    self.playRecord[self.timeNow] = [1, senderTag]
                }
                //print("time: \(self.timeNow) play record: \(self.dicToJSON(dic: self.playRecord))")
                print(senderTag)
            }
        }
    }
    
    func dicToJSON(dic:Dictionary<Double, Array<Any>>) -> String {
        var str = ""
        for i in dic.keys {
            if str != "" {
                str += ","
            }
            str += "\"\(i)\":[1.0"
            for j in 1..<dic[i]!.count {
                str += ",\(dic[i]![j])"
            }
            str += "]"
        }
        return "{" + str + "}"
    }
    
    func keyReleased(senderTag:Int){
        /* stop the sound file and restore the border of button to show user its deactivated status  */
        //print(senderTag)
        keyboardButtonList[senderTag].layer.borderWidth  = 1
    }
    
    func keyboardTouchStateChanged(senderTag:Int, add:Bool) {
        if add {
            if touchingKeyboards.firstIndex(of: senderTag) == nil {
                touchingKeyboards.append(senderTag)
                //print(touchingKeyboards)
            }
        }else if touchingKeyboards.firstIndex(of: senderTag) != nil {
            touchingKeyboards.remove(at: touchingKeyboards.firstIndex(of: senderTag)!)
        }
    }
    
    func startFreePlay() {
        connectionsLabel.text = "Your Turn"
        prepareBGM()  // Start the bgm file.
        
        /* Start timer to controll the change of scales along the bars.
         reloadSoundKey will be called when the bar changes. */
        var kanCount = 1
        kanPlayer?.play()
        let kanTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(60/bpm), repeats: true, block: {(kanTimer) in
            kanCount += 1
            if kanCount != 2 && kanCount != 4 {
                self.kanPlayer?.currentTime = 0
                self.kanPlayer?.play()
            }
            if kanCount >= 8 {
                kanTimer.invalidate()
                self.perform(#selector(self.startBGMPlayers), with: nil, afterDelay: TimeInterval(60/self.bpm))
            }
        })
    }
    
    @objc func startBGMPlayers() {
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(beat*(60/bpm)), repeats: true, block: { (timer) in //1小節終わるごとに呼ばれる
            if self.barNow == self.numberOfBar * self.chorusNumber!{
                timer.invalidate()
                print("finished!")
                Thread.sleep(forTimeInterval: 2.0) // Just I thought users would feel uncomfortable when the view is shut down suddenly after the bgm ended...
                self.terminateViewController()
            }else{
                if self.barNow % self.numberOfBar == 0{
                    self.bgmPlayers[self.chorusNumberNow].currentTime = 0.0
                    self.bgmPlayers[self.chorusNumberNow].play()
                    self.chorusNumberNow += 1
                }
                self.barNow += 1 //barnow: 今何小節目か numberofBar: 1コーラス何小節か
                self.reloadSoundKey()
            }
        })
        timer.fire()
        
        self.timeNow = 0.0
        let playerTimer = Timer.scheduledTimer(withTimeInterval: QUANTIZE, repeats: true, block: {(playerTimer) in
            self.timeNow += self.QUANTIZE
            self.timeNow = round(self.timeNow*10000)/10000
        })
    }
    
    //MARK: Get Data
    
    func jsonToDictionary(json: String) -> Dictionary<AnyHashable, Any> {
        let data = json.data(using: .utf8)!
        var dic:[AnyHashable: Any] = [:]
        do {
            dic = try (JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any])!
        } catch {
            print(error.localizedDescription)
        }
        return dic
    }
    
    deinit{
        print("A deinit")
    }
}

class VerticalSlider: UISlider {
    override func awakeFromNib() {
        super.awakeFromNib()
        transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        frame = superview!.bounds
    }
}
