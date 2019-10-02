//
//  ViewController.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/13.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

class PlayFullKeyboardViewController: UIViewController, AVAudioPlayerDelegate{
    var doTutorial:Bool? //これをfalseにするとTutorialをやらない
    var doSession:Bool? //botセッションをやるか
    var isFullKeyboard:Bool?
    
    var kanPlayer:AVAudioPlayer?
    var teacherPlayer:AVAudioPlayer?
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
    var notesNSArray:NSArray = []
    var uiParametersNSDict:NSDictionary = [:]
    var keyboardButtonList:[UIView] = []
    var pushedKeys:[Int] = [] // UIView tag playing sound now
    var playRecord:Dictionary<Double, Array<Any>> = Dictionary() //フリープレイ中の演奏データが記録される
    var aiPlay:Dictionary<Double, Array<Any>>? //ここに機械学習の演奏データが入る
    var userPlayable:Bool = true
    var botTurn:Bool = false
    var timeNowAI = 0.0 // timer used for AI's play
    //var startTime:Date = Date()
    var timeNow = 0.0 // timer for recording player's play
    var touchingKeyboards:[Int] = [] // UIView tag pushed now
    var pedalOn:Bool = false
    var kanTimer:Timer = Timer()
    var allTimers:[Timer] = []
    var allAudios:[AVAudioPlayer] = []
    
    let KEYBOARD_WIDTH = Double(7*5*50)
    let KEYBOARD_HEIGHT = Double(75*15)
    let QUANTIZE:Double = 1/324
    let BUFFER:Double = 0.01
    let INTRO_ID = 100
    
    let bService = BluetoothService()
    
    var tutorialMode:Bool = true
    var captionInteractive:Bool = false
    var tutorialCount:Int = 0
    var tutorialTexts:[Any]?
    var tutorialIndex:Int?
    var tutorialBGM:AVAudioPlayer = AVAudioPlayer()
    var tutorialBars:Int? // number of bars required for tutorial plays
    var tutorialNoteKeys:Array<Any> = []
    
    var primerMelody:String = "[" // To be posted to magenta in ec2 server.
    var primerMelodyValue:String = "" // To be posted to magenta in ec2 server.
    var steps_per_chord:Int = 32  // To be posted to magenta in ec2 server.
    
    var chordList:Array<String> = []
    var backingChords = ""
    
    var backFromAd:Bool = false
    
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIView!
    @IBOutlet weak var tutorialTextView: UITextView!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet var backBands: Array<UIImageView>?
    @IBOutlet weak var teacherBird: UIImageView!
    @IBOutlet weak var pedalBtn: UIButton!
    
    //MARK: Life Cycle
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
        // Line below tends to center the keyboard horizontally at the beggining, but does not work now. Please fix.
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: scrollView.contentSize.width/(-2), bottom: 0, right: 0)
        setVariables() //Initialize the member variables.
        setLayouts()
        prepareScales() // Register the scales used in the number.
        prepareSound() // Set the sound files activated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if backFromAd{
            self.dismiss(animated: false)
        }else{
            super.viewWillAppear(animated)
            startTutorialOnLaunch()
        }
    }
    
    func setVariables(){
        //bService.delegate = self
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
        self.notesNSArray = (NSDictionary(contentsOfFile: pathUtilityPlist! as! String)!["soundsList"] as! NSArray)
        self.uiParametersNSDict = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["uiParametersDict"] as! NSDictionary
        self.chordList = bgmNSDict["chordList"] as! Array
    }
    
    func setLayouts() {
        if isFullKeyboard!{
            for j in 0...6 {
                for i in 0...4 {
                    self.keyboardButtonList.append(makeKeyboard(i: i, d:0, j:j))
                }
                for i in 0...6 {
                    self.keyboardButtonList.append(makeKeyboard(i: i, d:1, j:j))
                }
                for i in keyboardButtonList {
                    self.stackView.addSubview(i)
                }
                for i in self.stackView.subviews {
                    if i.backgroundColor == UIColor.black {
                        self.stackView.bringSubviewToFront(i)
                    }
                }
            }
        }else{
            for j in 0..<15{ //vertical
                for i in 0..<10 { // horizontal
                    self.keyboardButtonList.append(makeFlatKeyboard(i: i, j: j))
                }
            }
            for i in keyboardButtonList {
                self.stackView.addSubview(i)
            }
            
            self.stackView.frame = CGRect(x:stackView.frame.origin.x , y: stackView.frame.origin.y, width: stackView.frame.width, height: CGFloat(KEYBOARD_HEIGHT))
        }
        self.keyboardButtonList = [UIView(), UIView(), UIView()] + self.keyboardButtonList + [UIView](repeating: UIView(), count: 80)
        
        if doTutorial! {
            for bird in backBands! {
                bird.isHidden = true
            }
        }else{
            nextBtn.isHidden = true
            tutorialTextView.textAlignment = .center
            tutorialTextView.backgroundColor = UIColor.clear
            if doSession!{
                tutorialTextView.text = "Bot Session"
            }else{
                teacherBird.isHidden = true
                tutorialTextView.text = "Free Play"
            }
        }
    }
    
    func makeKeyboard(i: Int, d:Int, j:Int) -> UIView {
        let btn = UIView()
        btn.tag = i+d*5+j*12+3
        let hakkenNum = Double(j)*7.0+floor(Double(i)/2.0) + Double(d*3) //白鍵の個数
        btn.frame = CGRect(x: /*(i-d*5)/2*50+d*150*/hakkenNum*50.0, y: 0, width: 50, height: 150)
        btn.backgroundColor = UIColor.white
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 1
        if i % 2 == 1 {
            btn.frame = CGRect(x: (hakkenNum+1)*50.0-33.5/2, y: 0, width: 33.5, height: 75)
            btn.backgroundColor = UIColor.black
        }
        return btn
    }
    
    func makeFlatKeyboard(i: Int, j:Int) -> UIView {
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
    
    override func viewDidLayoutSubviews() {
        if chorusNumberNow == 0 {
            if isFullKeyboard!{
                self.scrollView.setContentOffset(CGPoint(x: self.KEYBOARD_WIDTH*Double(0.5), y: 0), animated: false)
            }else{
                self.scrollView.setContentOffset(CGPoint(x: 0, y: (KEYBOARD_HEIGHT-Double(self.scrollView.frame.height))*Double(0.5)), animated: false)
            }
        }
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        if isFullKeyboard!{
            scrollView.contentOffset = CGPoint(x: KEYBOARD_WIDTH*Double(sender.value), y: 0)
        }else{
            scrollView.contentOffset = CGPoint(x: 0, y: (KEYBOARD_HEIGHT-Double(self.scrollView.frame.height))*Double(1.0-sender.value))
        }
    }
    
    @IBAction func pauseTapped() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let popupView = storyBoard.instantiateViewController(withIdentifier: "pause") as! PauseViewController
        popupView.parentTag = 0
        popupView.modalPresentationStyle = .overFullScreen
        popupView.modalTransitionStyle = .crossDissolve
        self.present(popupView, animated: true, completion: nil) 
    }
    
    @IBAction func pedalTapped(_ sender: Any) {
        pedalBtn.layer.backgroundColor = UIColor(red:150, green: 150, blue: 150, alpha: 1).cgColor
        pedalOn = true
    }
    
    
    @IBAction func pedalReleased(_ sender: Any) {
        pedalBtn.layer.backgroundColor = UIColor(red:236, green: 236, blue: 236, alpha: 1).cgColor
        audioPlayers.map{
            if $0.isPlaying{
                $0.setVolume(0.0, fadeDuration: 0.1)
            }
        }
        pedalOn = false
        
    }
    
    @IBAction func pedalReleasedOutside(_ sender: Any) {
        pedalBtn.layer.backgroundColor = UIColor(red:236, green: 236, blue: 236, alpha: 1).cgColor
        audioPlayers.map{
            if !$0.isPlaying{
                $0.setVolume(0.0, fadeDuration: 0.1)
            }
        }
        pedalOn = false
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
        allAudios += audioPlayers
        let pianoSoundsNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "sound/Count", ofType: "mp3")!)
        do {
            kanPlayer = try AVAudioPlayer(contentsOf: pianoSoundsNSURL as URL, fileTypeHint:nil)
        } catch {
            print(pianoSoundsNSURL)
            print("SoundのAVAudioPlayerインスタンス作成でエラー")
        }
        // 再生準備
        kanPlayer!.prepareToPlay()
        allAudios.append(kanPlayer!)
    }
    
    func prepareBGM(){
        /* Start BGM */
        bgmPlayers = []
        
        let bgmFileName = bgmNSDict.object(forKey:String("title")) as! String
        var bgmPlayer: AVAudioPlayer! = nil
        
        for i in 0...chorusNumber!{
            let rondomisedChorusNumber = Int.random(in: 1..<5)
            var bgmNSURL:NSURL?
            if i == 0 {
                bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmFileName))/intro", ofType: "mp3")!)
            }else if i != chorusNumber{
                bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmFileName))/chorus\(rondomisedChorusNumber)", ofType: "mp3")!)
            }else{
                bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmFileName))/last", ofType: "mp3")!)
            }
            do {
                bgmPlayer = try AVAudioPlayer(contentsOf: bgmNSURL! as URL, fileTypeHint:nil)
            } catch {
                print("BGMのAVAudioPlayerインスタンス作成でエラー")
            }
            
            if i == 0 {
                bgmPlayer.tag = INTRO_ID
            }
            bgmPlayer.currentTime = 0
            bgmPlayer.prepareToPlay()
            bgmPlayer.delegate = self
            print("bgm/\(String(describing: bgmFileName))/chorus\(rondomisedChorusNumber)")
            bgmPlayers.append(bgmPlayer)
        }
        allAudios += bgmPlayers
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
        for scaleNameNSString in (bgmNSDict.object(forKey:"scalesBaseList") as! NSArray){
            let scaleName = scaleNameNSString as! String
            if (Array(scalesDict.keys)).firstIndex(of: scaleName) == nil{
                setScalesDictForScaleName(scaleName: scaleName)
            }else{
                continue
            }
        }
    }
    
    func setScalesDictForScaleName(scaleName:String) {
        let notesInScale = (scalesNSDict.object(forKey:scaleName) as! NSArray) as! [Int]
        scalesDict[scaleName] = []
        for i in 0...12{
            scalesDict[scaleName] = scalesDict[scaleName]! + notesInScale.map{$0 + 12*i}
            if i > 6 && isFullKeyboard! {
                break
            }
        }
    }
    
    func reloadSoundKey(){
        /* Reload the scale when the ordered scale is changed.
         The color of every key in the scale would be colored so that users can distinguish it.
         */
        for keyboardButton in keyboardButtonList{
            if isFullKeyboard!{
                switch keyboardButton.tag % 12{
                case 0,2,3,5,7,8,10:
                    keyboardButton.layer.backgroundColor = UIColor(red:255, green: 255, blue: 255, alpha: 1).cgColor
                default:
                    keyboardButton.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
                }
            }else{
                keyboardButton.layer.backgroundColor = UIColor(red:255, green: 255, blue: 255, alpha: 1).cgColor
            }
        }
        if tutorialMode && tutorialTexts != nil{
            if tutorialNoteKeys.count == 3 {
                for noteKey in tutorialNoteKeys[2] as! [Int] {
                    for i in 0...6 {
                        keyboardButtonList[noteKey+i*12].layer.backgroundColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1).cgColor
                    }
                }
            }
        }else{
            let scaleNow:String = (bgmNSDict.object(forKey:"scalesList") as! NSArray)[(barNow-1)%self.numberOfBar] as! String

            for noteKey in scalesDict[scaleNow]!{
                keyboardButtonList[noteKey].layer.backgroundColor = UIColor(red:0, green: 255, blue: 255, alpha: 1).cgColor
            }
            let scaleBaseNow:String = (bgmNSDict.object(forKey:"scalesBaseList") as! NSArray)[(barNow-1)%self.numberOfBar] as! String
            for noteKey in scalesDict[scaleBaseNow]!{
                keyboardButtonList[noteKey].layer.backgroundColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1).cgColor
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player.tag == INTRO_ID {
            startMainBGM()
            return
        }
        if player.tag != nil {
            pushChanged(senderTag: player.tag!, add: false)
            audioPlayers[player.tag!].prepareToPlay()
        }
    }
    
    func startMainBGM() {
        self.chorusNumberNow = 1
        self.timeNow = 0.0
        let playerTimer = Timer.scheduledTimer(withTimeInterval: self.QUANTIZE, repeats: true, block: {(playerTimer) in
            self.timeNow += self.QUANTIZE
            self.timeNow = round(self.timeNow*10000)/10000
        })
        self.allTimers.append(playerTimer)
        let bgmTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.beat*(60/self.bpm)), repeats: true, block: { (bgmTimer) in //1小節終わるごとに呼ばれる
            if self.barNow == self.numberOfBar * self.chorusNumber!{
                bgmTimer.invalidate()
                print("finished!")
                Thread.sleep(forTimeInterval: 2.0) // Just I thought users would feel uncomfortable when the view is shut down suddenly after the bgm ended...
                //(self as? PlayFullKeyboardViewController)!.dismiss(animated: false, completion: nil)
                self.terminateViewController()
            }else{
                self.updateBGMTimer()
            }
        })
        bgmTimer.fire()
        self.allTimers.append(bgmTimer)
        if doSession! {
            let t = 0.25 / Double(self.steps_per_chord / 16)
            let aiTimer = Timer.scheduledTimer(withTimeInterval: t, repeats: true, block: {(aiTimer) in
                
                if self.aiPlay != nil {
                    //print("aiplay: \(self.aiPlay)")
                }
                if self.botTurn && self.aiPlay?[self.timeNowAI] != nil {
                    self.keyPushed(senderTag: self.aiPlay?[self.timeNowAI]![1] as! Int)
                    print("ai played \(self.aiPlay?[self.timeNowAI]![1] as! Int)")
                }
                self.timeNowAI += 0.25 //* Double(self.steps_per_chord / 16)
            })
            allTimers.append(aiTimer)
            let magentaTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval((60/bpm)/4), repeats: true, block: {(magentaTimer) in
                if self.barNow%self.numberOfBar==0{
                    self.primerMelody=""
                }
                if self.timeNow >= 0{
                    if self.primerMelody == ""{
                        self.primerMelody = "["
                    }
                    if self.primerMelodyValue != ""{
                        self.primerMelody = self.primerMelody + ", " + self.primerMelodyValue
                    }else if self.primerMelody == "["{
                        self.primerMelody = self.primerMelody + "-2"
                    }else{
                        self.primerMelody = self.primerMelody + ", -2"
                    }
                }
                self.primerMelodyValue = ""
            })
            allTimers.append(magentaTimer)
        }
    }
    
    func updateBGMTimer() {
        if self.barNow % self.numberOfBar == 0{
            self.bgmPlayers[self.chorusNumberNow].currentTime = 0.0
            self.bgmPlayers[self.chorusNumberNow].play()
            if !doSession! {
                let id = AppDelegate().getKeyChain(key: "userId")
                DispatchQueue.global().async {
                    if self.chorusNumberNow == self.chorusNumber {
                        _ = AppDelegate().httpRequest(route: "chorus_end", postBodyStr: "uuid=\(String(describing: id))&composition_name=\(String(describing: self.bgmNSDict.object(forKey:String("title")) as! String))&chorus=last&sequence=\(self.playRecord)")
                    }else{
                        _ = AppDelegate().httpRequest(route: "chorus_end", postBodyStr: "uuid=\(String(describing: id))&composition_name=\(String(describing: self.bgmNSDict.object(forKey:String("title")) as! String))&chorus=\(self.chorusNumberNow)&sequence=\(self.playRecord)")
                    }
                }
            }
            
            self.timeNowAI = 0.0
            self.timeNow = 0.0
            self.playRecord = [:]
            self.chorusNumberNow += 1
            
            /*if self.doSession! {
                botTurn = !botTurn
                switch self.botTurn {
                case false: self.connectionsLabel.text = "Your Turn"
                case true:
                    self.connectionsLabel.text = "Partner's Turn"
                    for i in self.touchingKeyboards {
                        self.keyboardButtonList[i].layer.borderWidth  = 1
                    }
                }
            }*/
        }
        if self.doSession! {
            if self.barNow % 4 == 3{
                let barNowInChorus = self.barNow % self.numberOfBar
                self.backingChords = ""
                for i in 0...(barNowInChorus+4)%numberOfBar{
                    self.backingChords += (self.chordList[i] + " ")
                }
                DispatchQueue.global().async {
                    self.primerMelody = self.primerMelody.replacingOccurrences(of: "[-2", with: "[60")
                    self.primerMelody = self.primerMelody.replacingOccurrences(of: "[, ", with: "[") + "]"
                    print(self.primerMelody)
                    print(self.backingChords)
                    AppDelegate().httpRequest(route: "generate", postBodyStr: "primer_melody=\(self.primerMelody)&backing_chords=\(self.backingChords)&steps_per_chord=\(self.steps_per_chord)", calledBy: self)
                    self.primerMelody = self.primerMelody.replacingOccurrences(of: "]", with: "")
                
                }
            }
            if self.barNow % 4 == 0 && self.barNow != 0 {
                botTurn = !botTurn
                switch self.botTurn {
                case false: self.connectionsLabel.text = "Your Turn"
                case true:
                    self.connectionsLabel.text = "Partner's Turn"
                    for i in self.touchingKeyboards {
                        self.keyboardButtonList[i].layer.borderWidth  = 1
                    }
                }
            }
        }
        self.barNow += 1 //barnow: 今何小節目か numberofBar: 1コーラス何小節か
        self.reloadSoundKey()
    }
    
    //MARK: Touches
    
    @IBAction func gotoNextTutorial() {
        if captionInteractive {
            commitTutorial()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if userPlayable{
            for touch in touches {
                let point = touch.location(in: self.stackView)
                let hitView = self.stackView.hitTest(point, with: event)
                if (hitView != nil) {
                    let tag = hitView!.tag
                    self.pushChanged(senderTag: tag, add: true)
                    
                    self.keyPushed(senderTag: tag, userPushed: true)
                    self.keyboardTouchStateChanged(senderTag: tag, add: true)
                }
            }
            
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if userPlayable{
            var touchedKeys:[Int] = []
            for touch in touches {
                let point = touch.location(in: self.stackView)
                let hitView = self.stackView.hitTest(point, with: event)
                if (hitView != nil) {
                    touchedKeys.append(hitView!.tag)
                    if pushedKeys.firstIndex(of: hitView!.tag) == nil || touchingKeyboards.firstIndex(of: hitView!.tag) == nil {
                        keyPushed(senderTag: hitView!.tag, userPushed: true)
                    }
                    pushChanged(senderTag: hitView!.tag, add: true)
                }
            }
            touchingKeyboards = touchedKeys
            for i in keyboardButtonList {
                if touchingKeyboards.firstIndex(of: i.tag) == nil {
                    self.keyReleased(senderTag: i.tag)
                }else{
                    i.layer.borderWidth = 3
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if userPlayable {
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
            if self.audioPlayers[senderTag].isPlaying{
                self.audioPlayers[senderTag].stop()
            }
            self.audioPlayers[senderTag].setVolume(1.0, fadeDuration: 0.0001)
            self.audioPlayers[senderTag].currentTime = 0
            self.audioPlayers[senderTag].play()
            
            self.primerMelodyValue = String(senderTag+21)
            
            if userPushed && self.timeNow != 0.0 {
                let timeToRecord = round(self.QUANTIZE * Double(Int( (self.bgmPlayers[self.chorusNumberNow-1].currentTime)/self.QUANTIZE))*10000)/10000
                print(timeToRecord)
                if self.playRecord[timeToRecord] != nil {
                    self.playRecord[timeToRecord]?.append(senderTag)
                }else {
                    self.playRecord[timeToRecord] = [1, senderTag]
                }
                print("time: \(timeToRecord) play record: \(self.dicToJSON(dic: self.playRecord))")
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
        DispatchQueue.global().async{
            if !self.pedalOn{
                self.audioPlayers[senderTag].setVolume(0.0, fadeDuration: 0.1)
            }
        }
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
    
    //MARK: Tutorial
    
    func startTutorialOnLaunch() {
        userPlayable = !doTutorial!
        if doTutorial! {
            if tutorialIndex == nil {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let popupView = storyBoard.instantiateViewController(withIdentifier: "selector") as! TutorialSelectorViewController
                popupView.modalPresentationStyle = .overFullScreen
                popupView.modalTransitionStyle = .crossDissolve
                self.present(popupView, animated: true, completion: nil)
            }else{
                let filePath = Bundle.main.path(forResource: "Tutorial", ofType: "plist")
                let plist = NSDictionary(contentsOfFile: filePath!)
                tutorialTexts = plist![plist!.allKeys[tutorialIndex!]] as? [Any]
                tutorialTextView.text = tutorialTexts![0] as? String
                tutorialMode = doTutorial!
                connectionsLabel.text = "Tutorial"
                captionInteractive = doTutorial!
            }
        }else{
            startFreePlay()
        }
    }
    
    func commitTutorial() {
        tutorialCount += 1
        switch tutorialTexts![tutorialCount] as? String {
        case "TeacherPlayFlag":
            connectionsLabel.text = "Teacher's Turn"
            tutorialTextView.text = tutorialTexts![tutorialCount-1] as? String
            tutorialCount += 1
            tutorialBars = (tutorialTexts![tutorialCount] as? Array<Any>)!.first as? Int
            tutorialNoteKeys = (tutorialTexts![tutorialCount] as? Array<Any>)!
            
            /*let json = (tutorialTexts![tutorialCount] as? Array<Any>)![1]
            let nakatugidic = jsonToDictionary(json: json as! String) as! [String: Array<Any>] //json変換の中継ぎ
            var dic:[Double: Array<Any>] = [:]
            for i in nakatugidic.keys {
                dic[atof(i)] = nakatugidic[i]
            }
            
            print("dic: \(String(describing: dic))")
            captionInteractive = false
            connectionsLabel.text = "Teacher's Turn"
            self.timeNowAI = 0.0
            var count = 0
            let autoTimer = Timer.scheduledTimer(withTimeInterval: QUANTIZE, repeats: true, block: {(autoTimer) in
                if dic[self.timeNowAI] != nil {
                    for i in 1..<dic[self.timeNowAI]!.count {
                        self.keyPushed(senderTag: dic[self.timeNowAI]![i] as! Int)
                    }
                }
                count += 1
                if count % 324 == 0 {
                    print("current time: \(self.tutorialBGM.currentTime)")
                    print("timenowAI: \(self.timeNowAI)")
                }
                self.timeNowAI += self.QUANTIZE
                self.timeNowAI = round(self.timeNowAI*10000)/10000
                if Float(self.timeNowAI) > Float(self.tutorialBars!)*(self.beat*(60/self.bpm)) {
                    autoTimer.invalidate()
                }
            })
            allTimers.append(autoTimer)*/
            let playTitle = (tutorialTexts![tutorialCount] as? Array<Any>)![1] as! Int
            let path = Bundle.main.path(forResource: "bgm/teacherPlay/lesson1/\(playTitle)withBGM", ofType: "mp3")
            do{
                teacherPlayer = try AVAudioPlayer(contentsOf: NSURL(fileURLWithPath: path!) as URL, fileTypeHint:nil)
            }catch{}
            teacherPlayer!.currentTime = 0
            teacherPlayer!.prepareToPlay()
            teacherPlayer!.play()
            allAudios.append(teacherPlayer!)
            captionInteractive = false
            playTutorialBGM(forBar: tutorialBars!)
            
        case "PlayerPlayFlag":
            tutorialTextView.text = tutorialTexts![tutorialCount-1] as? String
            connectionsLabel.text = "Your Turn"
            captionInteractive = false
            userPlayable = true
            playTutorialBGM(forBar: tutorialBars!)
        case "ReplayFlag":
            let alert = UIAlertController(title: "お手本を聴いてもう一度やる？", message: nil, preferredStyle: UIAlertController.Style.alert)
            let yes = UIAlertAction(title: "はい", style: UIAlertAction.Style.default, handler: { (yes) in
                while self.tutorialTexts![self.tutorialCount+1] as? String != "TeacherPlayFlag" {
                    self.tutorialCount -= 1
                    self.tutorialTextView.text = self.tutorialTexts![self.tutorialCount] as? String
                }
                })
            let no = UIAlertAction(title: "いいえ", style: UIAlertAction.Style.default, handler: { (no) in
                    self.tutorialCount += 1
                self.tutorialTextView.text = self.tutorialTexts![self.tutorialCount] as? String
                })
            alert.addAction(yes)
            alert.addAction(no)
            present(alert, animated: true, completion: nil)
        case "SummaryFlag":
            endTutorial()
        default:
            connectionsLabel.text = "Tutorial"
            tutorialTextView.text = tutorialTexts![tutorialCount] as? String
            break
        }
    }
    
    func endTutorial() {
        let ud = UserDefaults.standard
        var completed:[Int] = []
        if let data = ud.value(forKey: "completedTutorials"){
            completed = data as! [Int]
        }
        if completed.firstIndex(of: tutorialIndex!) == nil {
            completed.append(tutorialIndex!)
            ud.set(completed, forKey: "completedTutorials")
            ud.synchronize()
        }
        tutorialMode = false
        captionInteractive = false
        userPlayable = false
        /*route="tutorial_end", postBodyStr="uuid=[端末のuuid]&lesson_completed=[チュートリアル番号]” 返り値なし*/
        AppDelegate().httpRequest(route: "tutorial_end", postBodyStr: "uuid=\(UUID().uuid)&lesson_completed=\(tutorialIndex! + 1)")
        
        self.performSegue(withIdentifier: "toSummary", sender: nil)
    }
    
    func playTutorialBGM(forBar: Int) {
        do {
            tutorialBGM = try AVAudioPlayer(contentsOf: NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmNSDict.object(forKey:String("title")) as! String))/chorus1", ofType: "mp3")!) as URL, fileTypeHint:nil)
        } catch {
            print("BGMのAVAudioPlayerインスタンス作成でエラー")
        }
        tutorialBGM.prepareToPlay()
        allAudios.append(tutorialBGM)
        
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(beat*(60/bpm)), repeats: true, block: { (timer) in //1小節終わるごとに呼ばれる
            self.updateTutorialTimer(timer: timer, bar: forBar)
        })
        timer.fire()
        allTimers.append(timer)
    }
    
    func updateTutorialTimer(timer:Timer = Timer(), bar: Int) {
        if self.barNow == bar{
            timer.invalidate()
            self.barNow = 0
            self.chorusNumber = 0
            self.tutorialBGM.stop()
            self.tutorialBGM.prepareToPlay()
            self.tutorialBGM.currentTime = 0
            self.captionInteractive = true
            self.userPlayable = false
            self.commitTutorial()
        }else{
            if self.barNow % self.numberOfBar == 0{
                if userPlayable{
                    self.tutorialBGM.currentTime = 0.0
                    self.tutorialBGM.play()
                }
                self.chorusNumberNow += 1
            }
            self.reloadSoundKey()
            self.barNow += 1 //barnow: 今何小節目か numberofBar: 1コーラス何小節か
        }
    }
    
    func startFreePlay() {
        //tutorialTextView.text = "フリープレイ"
        connectionsLabel.text = "Your Turn"
        prepareBGM()  // Start the bgm file.
        //startTime = Date()
        
        var kanCount = 1
        kanPlayer?.play()
        kanTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(60/bpm), repeats: true, block: {(kanTimer) in
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
        allTimers.append(kanTimer)
    }
    
    @objc func startBGMPlayers() {
        let playIntro = bgmNSDict.object(forKey:String("intro")) as! Bool
        if playIntro {
            self.bgmPlayers[0].play()
        }else{
            startMainBGM()
        }
    }
    
    //MARK: Data
    
    func getAIDic(json: String) {
        let nakatugidic = self.jsonToDictionary(json: json as! String) as! [String: Array<Any>]
        self.aiPlay = [:]
        for i in nakatugidic.keys {
            self.aiPlay![atof(i)] = nakatugidic[i]
        }
    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toSummary":
            let vc: TutorialSummaryViewController = (segue.destination as? TutorialSummaryViewController)!
            vc.path = "html/tutorialSummary/\(tutorialIndex! + 1)"
        default:
            break
        }
    }
    
    func terminateViewController() {
        for i in allAudios {
            i.stop()
        }
        for timer in allTimers {
            timer.invalidate()
        }
        presentAd(currentVC: self)
        //self.dismiss(animated: true, completion: nil)
    }
}

/*extension PlayFullKeyboardViewController : BluetoothServiceDelegate {
    
    func connectedDevicesChanged(manager: BluetoothService, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.connectionsLabel.text = "Connections: \(connectedDevices)"
        }
    }
    
    func colorChanged(manager: BluetoothService, colorString: String) {
        OperationQueue.main.addOperation {
            self.keyPushed(senderTag: Int(colorString)!)
        }
    }
    
}*/

class PauseViewController: UIViewController {
    var parentTag: Int?
    
    @IBAction func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func quitTapped() {
        let secondVc = self.presentingViewController as? PlayFullKeyboardViewController
        secondVc!.dismiss(animated: false, completion: nil)
        secondVc!.terminateViewController()
    }
}

class TutorialSelectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var headerLabel: UILabel = UILabel()
    var headerView: UIView = UIView()
    var list:[String] = []
    var completed:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let ud = UserDefaults.standard
        if let data = ud.value(forKey: "completedTutorials") {
            completed = data as! [Int]
        }
        
        let filePath = Bundle.main.path(forResource: "Tutorial", ofType: "plist")!
        let plist = NSDictionary(contentsOfFile: filePath)
        list = plist?.allKeys as! [String]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel!.text = list[indexPath.row]
        cell.accessoryType = .none
        if completed.firstIndex(of: indexPath.row) != nil {
            cell.accessoryType = .checkmark
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != 1{ //Tutorial2が実装されたら消去
            let vc = self.presentingViewController as! PlayFullKeyboardViewController
            vc.tutorialIndex = indexPath.row
            self.dismiss(animated: true, completion: nil)
            vc.startTutorialOnLaunch()
        }
    }
}

extension UIScrollView {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesBegan(touches, with: event)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesMoved(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesEnded(touches, with: event)
    }
}

var StoredPropertyKey: UInt8 = 0
extension AVAudioPlayer {
    var tag: Int? {
        get {
            guard let object = objc_getAssociatedObject(self, &StoredPropertyKey) as? Int else {
                return nil
            }
            return object
        }
        set {
            objc_setAssociatedObject(self, &StoredPropertyKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
