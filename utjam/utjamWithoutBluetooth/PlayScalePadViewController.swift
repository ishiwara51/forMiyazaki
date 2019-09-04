//
//  ViewController.swift
//  utjam
//
//  Created by 加納大地 on 2019/06/13.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit
import AVFoundation

class PlayScalePadViewController: UIViewController {
    
    @IBOutlet weak var keyboardUpper1: UIButton!
    @IBOutlet weak var keyboardUpper2: UIButton!
    @IBOutlet weak var keyboardUpper3: UIButton!
    @IBOutlet weak var keyboardUpper4: UIButton!
    @IBOutlet weak var keyboardUpper5: UIButton!
    @IBOutlet weak var keyboardUpper6: UIButton!
    @IBOutlet weak var keyboardUpper7: UIButton!
    @IBOutlet weak var keyboardUpper8: UIButton!

    @IBOutlet weak var keyboardLower1: UIButton!
    @IBOutlet weak var keyboardLower2: UIButton!
    @IBOutlet weak var keyboardLower3: UIButton!
    @IBOutlet weak var keyboardLower4: UIButton!
    @IBOutlet weak var keyboardLower5: UIButton!
    @IBOutlet weak var keyboardLower6: UIButton!
    @IBOutlet weak var keyboardLower7: UIButton!
    @IBOutlet weak var keyboardLower8: UIButton!

    @IBOutlet weak var buttonChangeHigher: UIButton!
    @IBOutlet weak var bottonChangeLower: UIButton!
    // declare the variables to be initialized in init()
    
    var audioPlayers:[AVAudioPlayer] = []
    var bgmPlayer: AVAudioPlayer! = nil
    var listSoundKeyHigher:[Int] = []
    var listSoundKeyLower:[Int] = []
    var octaveForLower:Int = 0 //0<4 for octave 1~5
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
    var pianoKeysNSArray:NSArray = []
    var uiParametersNSDict:NSDictionary = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        // Do any additional setup after loading the view.
        setVariables() //Initialize the member variables.
        prepareSound() // Set the sound files activated.
        startBGM()  // Start the bgm file.
        
        /* Start timer to controll the change of scales along the bars.
         relodeSoundKey will be called when the bar changes. */
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(beat*(60/bpm)), repeats: true, block: { (timer) in
            if self.barNow == self.numberOfBar{
                timer.invalidate()
                print("finished!")
                Thread.sleep(forTimeInterval: 2.0)
                self.terminateViewController()
            }else{
                self.barNow += 1
                self.relodeSoundKey()
            }
        })
        // Start clock loop right after the BGM starts.
        
    }
    
    func setVariables(){
        self.audioPlayers = []
        self.listSoundKeyHigher = []
        self.listSoundKeyLower = []
        self.octaveForLower = 0 //0<5 for octave 1~6
        self.pathUtilityPlist = Bundle.main.path(forResource: "Utility", ofType: "plist")
        self.bgmNSDictPre = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["bgmDict"] as! NSDictionary
        self.bgmNSDict = self.bgmNSDictPre.object(forKey:bgmTag) as! NSDictionary
        self.bpm = bgmNSDict.object(forKey:"bpm") as! Float
        self.beat = bgmNSDict.object(forKey:"beat") as! Float
        self.numberOfBar = bgmNSDict.object(forKey:"numberOfBar") as! Int
        self.barNow = 0
        self.scalesNSDict = (NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["scalesDict"] as! NSDictionary)["short"] as! NSDictionary
        self.pianoKeysNSArray = (NSDictionary(contentsOfFile: pathUtilityPlist! as! String)!["soundsList"] as! NSArray)
        self.uiParametersNSDict = NSDictionary(contentsOfFile:self.pathUtilityPlist! as! String)!["uiParametersDict"] as! NSDictionary
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func octaveHigherTouchDown(_ sender: UIButton) {
    /* Called to make the octave one higher when users push buttonChangeHigher */
        print(octaveForLower)
        if octaveForLower <= 5{
            octaveForLower += 1
            self.relodeSoundKey()
        }
    }
    @IBAction func octaveLowerTouchDown(_ sender: UIButton) {
    /* Called to make the octave one lower when users push buttonChangeLower */
        print(octaveForLower)
        if octaveForLower >= 1{
            octaveForLower -= 1
            self.relodeSoundKey()
        }
    }
    @IBAction func keyboardTouchDown(_ sender: UIButton) {
    /* play a sound file and emphasize the border of button to show user its activated status when users push a key button. */
        audioPlayers[sender.tag].currentTime = 0
        audioPlayers[sender.tag].play()
        sender.layer.borderWidth = 3
    }
    @IBAction func keyboardTouchUp(_ sender: UIButton) {
    /* Stop a sound file and restore the border of button to show user its deactivated status when users push a key button. */
        //audioPlayers[sender.tag].stop() // Commented out now because this makes some noize.
        sender.layer.borderWidth = 1
    }
    @IBAction func keyboardDragEnter(_ sender: UIButton) {
    /* Play a sound file and emphasize the border of button to show user its active status when users drag into a key button. */
        let keynum = sender.tag
        audioPlayers[sender.tag].currentTime = 0
        audioPlayers[sender.tag].play()
        sender.layer.borderWidth = 3
    }

    @IBAction func keyboardDragExit(_ sender: UIButton) {
    /* Stop a sound file and restore the border of button to show user its deactivated status when users drug out of a key button. */
        // audioPlayers[sender.tag].stop() // Commented out now because this makes some noize.
        sender.layer.borderWidth = 1
    }

    func prepareSound(){
    /* Activate the sound files for immediate play when the user push keys.
     When a key button is pushed by user, the sound with index of the key's tab will be played. */
        var audioPlayer: AVAudioPlayer! = nil

        for keyNSTaggedPointerString in pianoKeysNSArray{
            let key = keyNSTaggedPointerString as! String
            let pianoSoundsNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "sound/\(key)", ofType: "mp3")!)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: pianoSoundsNSURL as URL, fileTypeHint:nil)
            } catch {
                print(pianoSoundsNSURL)
                print("SoundのAVAudioPlayerインスタンス作成でエラー")
            }
            // 再生準備
            // Do any additional setup after loading the view, typically from a nib.
            audioPlayer.prepareToPlay()
            audioPlayers.append(audioPlayer)
        }
    }

    func startBGM(){
    /* Start BGM */
        let bgmFileName = bgmNSDict.object(forKey:String("title")) as! String
        print(bgmFileName)
        let bgmNSURL = NSURL(fileURLWithPath: Bundle.main.path(forResource: "bgm/\(String(describing: bgmFileName))", ofType: "mp3")!)
        do {
            self.bgmPlayer = try AVAudioPlayer(contentsOf: bgmNSURL as URL, fileTypeHint:nil)
        } catch {
            print("BGMのAVAudioPlayerインスタンス作成でエラー")
        }
        self.bgmPlayer.currentTime = 0
        self.bgmPlayer.prepareToPlay()
        self.bgmPlayer.play()

    }

    func relodeSoundKey(){
    /* Relode the scale and reset the note of each pad when the ordered scale is changed or buttonChangeOctave is pressed.
        Now this works little too slow. Please improve if its possible. */
        let scaleNow:String = (bgmNSDict.object(forKey:"scalesList") as! NSArray)[barNow-1] as! String
        // Load notes array for barNow-scale from scalesDict
        let soundNSArrayInScaleNow: NSArray = scalesNSDict.object(forKey:scaleNow) as! NSArray
        // Convert barNow-scale NSArray-to-Array(Int)
        var soundListInScaleNow:[Int] = []
        for soundNSString in soundNSArrayInScaleNow{
            let sound:Int = soundNSString as! Int
            soundListInScaleNow.append(sound)
        }
        // Adjust the notes in soundListInScaleNow to the octaves of pads.
        listSoundKeyLower = soundListInScaleNow.map{$0+(12*octaveForLower)}
        listSoundKeyHigher = listSoundKeyLower.map{$0+12}
        // Make lists of the button instances.
        let keyboardLowerList:[UIButton] = [self.keyboardLower1, self.keyboardLower2, self.keyboardLower3, self.keyboardLower4, self.keyboardLower5, self.keyboardLower6, self.keyboardLower7, self.keyboardLower8]
        let keyboardUpperList:[UIButton] = [self.keyboardUpper1, self.keyboardUpper2, self.keyboardUpper3, self.keyboardUpper4, self.keyboardUpper5, self.keyboardUpper6, self.keyboardUpper7, self.keyboardUpper8]
        // Initialize the button instances' tag with 88, which matches the index of Empty sound file.
        for keyboard in keyboardLowerList{
            keyboard.tag = 88
        }
        for keyboard in keyboardUpperList{
            keyboard.tag = 88
        }
        // Set the note on each pad.
        for (indice, soundKey) in listSoundKeyLower.enumerated(){
          if 0 <= soundKey && soundKey <= 87{
            keyboardLowerList[indice].tag = soundKey
          }
        }
        for (indice, soundKey) in listSoundKeyHigher.enumerated(){
          if 0 <= soundKey && soundKey <= 87{
            keyboardUpperList[indice].tag = soundKey
          }
        }
    }
    
    func terminateViewController(){
        self.presentingViewController?.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    deinit{
        print("A deinit")
    }
    

}
