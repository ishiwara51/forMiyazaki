//
//  OptionSelectViewController.swift
//  utjamBluetooth
//
//  Created by Macky on 2019/08/09.
//  Copyright © 2019 加納大地. All rights reserved.
//

import UIKit
import MYPassthrough

class OptionSelectViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var isFirstLaunch:Bool?
    
    @IBOutlet weak var musicSelector:UIPickerView!
    @IBOutlet weak var chorusSlider:UISlider!
    @IBOutlet weak var tutorialSegment:UISegmentedControl!
    @IBOutlet weak var keytypeSegment:UISegmentedControl!
    @IBOutlet weak var chorusLabel:UILabel!
    @IBOutlet weak var startButton:UIButton!
    @IBOutlet weak var menuButton:UIButton!
    @IBOutlet weak var exprLabel: UILabel!
    
    let list = ["The Chicken", "Isn't She Lovely", "Just the Two of Us"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        musicSelector.selectRow(1, inComponent: 0, animated: false)
        modeChanged(tutorialSegment)
        sliderMoved()
        
        if isFirstLaunch ?? false{
            startTutorial()
        }
    }
    
    func startTutorial() {
        PassthroughManager.shared.labelCommonConfigurator = {
            labelDescriptor in
            
            labelDescriptor.label.font = .systemFont(ofSize: 20)
            labelDescriptor.widthControl = .precise(300)
        }
        
        PassthroughManager.shared.infoCommonConfigurator = {
            infoDescriptor in
            
            infoDescriptor.label.font = .systemFont(ofSize: 20)
            infoDescriptor.widthControl = .precise(300)
        }
        
        PassthroughManager.shared.closeButton.setTitle("Skip", for: .normal)
        
        let labelDescriptor = LabelDescriptor(for: "BGMを選びましょう。\n初めての方は Isn’t She Lovely が\nオススメです。")
        labelDescriptor.position = .bottom
        let holeViewDescriptor = HoleViewDescriptor(view: musicSelector, type: .rect(cornerRadius: 5, margin: 0))
        holeViewDescriptor.labelDescriptor = labelDescriptor
        let task = PassthroughTask(with: [holeViewDescriptor])
        
        let labelDescriptor2 = LabelDescriptor(for: "1プレイの長さを設定しましょう。\n横の数字はコーラス数です。")
        labelDescriptor2.position = .bottom
        let holeViewDescriptor2 = HoleViewDescriptor(view: chorusSlider, type: .rect(cornerRadius: 5, margin: 0))
        holeViewDescriptor2.labelDescriptor = labelDescriptor2
        let task2 = PassthroughTask(with: [holeViewDescriptor2])
        
        let labelDescriptor3 = LabelDescriptor(for: "モードを選びましょう。")
        labelDescriptor3.position = .bottom
        let holeViewDescriptor3 = HoleViewDescriptor(view: tutorialSegment, type: .rect(cornerRadius: 5, margin: 0))
        holeViewDescriptor3.labelDescriptor = labelDescriptor3
        let task3 = PassthroughTask(with: [holeViewDescriptor3])
        
        let labelDescriptor4 = LabelDescriptor(for: "それぞれのモードの説明は\nこちらから詳しくご覧になれます。")
        labelDescriptor4.position = .bottom
        let holeViewDescriptor4 = HoleViewDescriptor(view: menuButton, type: .rect(cornerRadius: 5, margin: 0))
        holeViewDescriptor4.labelDescriptor = labelDescriptor4
        let task4 = PassthroughTask(with: [holeViewDescriptor4])
        
        let labelDescriptor5 = LabelDescriptor(for: "準備ができたら、こちらから演奏を開始しましょう。")
        labelDescriptor5.position = .bottom
        let holeViewDescriptor5 = HoleViewDescriptor(view: startButton, type: .rect(cornerRadius: 5, margin: 0))
        holeViewDescriptor5.labelDescriptor = labelDescriptor5
        let task5 = PassthroughTask(with: [holeViewDescriptor5])
        
        PassthroughManager.shared.display(tasks: [task, task2, task3, task4, task5])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0: exprLabel.text = "自由に演奏が楽しめるモードです。"
        case 1: exprLabel.text = "即興演奏について学べるモードです。"
        case 2: exprLabel.text = "AIとセッションができるモードです。"
        default: return
        }
    }
    
    @IBAction func startBtnTapped() {
        if tutorialSegment!.selectedSegmentIndex == 2 && !Network.isOnline(){
            let alert = UIAlertController(title: "サーバーと正常に通信できませんでした。\nBotSessionモードはオンラインでのみお楽しみいただけます。", message: nil, preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }else{
            if !Network.isOnline(){
                let alert = UIAlertController(title: "サーバーと正常に通信できませんでした。\n演奏データの収集のため、オンラインでのプレイをお願いしています。", message: nil, preferredStyle: .alert)
                let ignore = UIAlertAction(title: "無視して続ける", style: .default, handler: {[weak alert] (action) -> Void in
                    switch self.keytypeSegment.selectedSegmentIndex {
                    case 0:
                        self.performSegue(withIdentifier: "toFull", sender: nil)
                    case 1:
                        self.performSegue(withIdentifier: "toFlat", sender: nil)
                    case 2:
                        self.performSegue(withIdentifier: "toHonda", sender: nil)
                    default:
                        break
                    }
                })
                let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(ok)
                alert.addAction(ignore)
                present(alert, animated: true, completion: nil)
            }else{
                switch self.keytypeSegment.selectedSegmentIndex {
                case 0:
                    self.performSegue(withIdentifier: "toFull", sender: nil)
                case 1:
                    self.performSegue(withIdentifier: "toFlat", sender: nil)
                case 2:
                    self.performSegue(withIdentifier: "toHonda", sender: nil)
                default:
                    break
                }
            }
        }
    }
    
    @IBAction func sliderMoved() {
        chorusLabel.text = "Chorus: \(Int(self.chorusSlider.value*10+1))"
    }
    
    @IBAction func keyTypeChanged() {
        if keytypeSegment.selectedSegmentIndex == 2 {
            tutorialSegment.selectedSegmentIndex = 0
            tutorialSegment.isHidden = true
        }else{
            tutorialSegment.isHidden = false
        }
    }
    
    @IBAction func presentPopup() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let popupView: SummarySelectViewController = storyBoard.instantiateViewController(withIdentifier: "popup") as! SummarySelectViewController
        popupView.modalPresentationStyle = .overFullScreen
        popupView.modalTransitionStyle = .crossDissolve
        self.present(popupView, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return list.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return list[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 1:
            tutorialSegment.setEnabled(true, forSegmentAt: 2)
        default:
            tutorialSegment.setEnabled(false, forSegmentAt: 2)
            tutorialSegment.selectedSegmentIndex = 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toFull":
            let vc: PlayFullKeyboardViewController = (segue.destination as? PlayFullKeyboardViewController)!
            vc.bgmTag = "\(self.musicSelector.selectedRow(inComponent: 0))"
            vc.chorusNumber = Int(self.chorusSlider.value*10+1)
            vc.doTutorial = (tutorialSegment!.selectedSegmentIndex == 1)
            vc.doSession = (tutorialSegment!.selectedSegmentIndex == 2)
            vc.isFullKeyboard = true
        case "toFlat":
            let vc: PlayFullKeyboardViewController = (segue.destination as? PlayFullKeyboardViewController)!
            vc.bgmTag = "\(self.musicSelector.selectedRow(inComponent: 0))"
            vc.chorusNumber = Int(self.chorusSlider.value*10+1)
            vc.doTutorial = (tutorialSegment!.selectedSegmentIndex == 1)
            vc.doSession = (tutorialSegment!.selectedSegmentIndex == 2)
            vc.isFullKeyboard = false
        case "toHonda":
            let vc: PlayFullKeyboardViewController = (segue.destination as? PlayFullKeyboardViewController)!
            vc.bgmTag = "\(self.musicSelector.selectedRow(inComponent: 0))"
            vc.chorusNumber = Int(self.chorusSlider.value*10+1)
            vc.doTutorial = false
            vc.doSession = false
            vc.isFullKeyboard = true
        default:
            break
        }
    }
    
}

class SummarySelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backBtn: UIButton!
    var notInParent = false
    var selectedIndex = 0
    var tutorialSummaries:Dictionary<String, String> = [:]
    let list = ["本アプリについて", "各モードとその操作", "開発者からのメッセージ (お読みください)", "プライバシーポリシー", "引き継ぎコード発行", "お問い合わせ"]
    var htmlPath:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let filePath = Bundle.main.path(forResource: "Menu", ofType: "plist")!
        let plist = NSDictionary(contentsOfFile: filePath)
        tutorialSummaries = (plist! as? Dictionary<String, String>)!
    }
    
    @IBAction func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backBtnTapped() {
        notInParent = false
        self.tableView.reloadData()
        backBtn.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !notInParent {
            return list.count
        }else {
            return tutorialSummaries.keys.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if !notInParent {
            cell.textLabel!.text = list[indexPath.row]
        }else{
            cell.textLabel!.text = ([String](tutorialSummaries.keys))[indexPath.row]
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        if !notInParent {
            switch indexPath.row {
            case 0:
                self.htmlPath = "html/general_expr"
                self.performSegue(withIdentifier: "toSelectedSummary", sender: nil)
            case 1:
                notInParent = true
                backBtn.isHidden = false
                self.tableView.reloadData()
            case 2:
                self.htmlPath = "html/message"
                self.performSegue(withIdentifier: "toSelectedSummary", sender: nil)
            case 3:
                let url = URL(string: "https://nend.net/privacy/sdkpolicy")
                UIApplication.shared.open(url!)
            case 4:
                presentCodeOutputAlert()
            case 5:
                let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSdaFs5tnxx_0hq5n3-HVkqOX9EhvdMLxqJaCXW2Su5cbmwKTQ/viewform")
                UIApplication.shared.open(url!)
            default:
                break
            }
        }else{
            self.performSegue(withIdentifier: "toSelectedSummary", sender: nil)
        }
        self.tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func presentCodeOutputAlert() {
        _ = AppDelegate().httpRequest(route: "transfer_id_created", postBodyStr: "uuid=\(UUID().uuidString)", calledBy: self, callTag: 1)
    }
    
    func getTransferID(id: String!) {
        let alert = UIAlertController(title: "あなたの引き継ぎコードは\(id!)です", message: nil, preferredStyle: .alert)
        let copy = UIAlertAction(title: "コピー", style: .default, handler: {[weak alert] (action) -> Void in
            UIPasteboard.general.string = id
        })
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        
        alert.addAction(copy)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toSelectedSummary":
            if notInParent{
                let vc: TutorialSummaryViewController = (segue.destination as? TutorialSummaryViewController)!
                vc.path = tutorialSummaries[([String](tutorialSummaries.keys))[selectedIndex]]
            }else{
                let vc: TutorialSummaryViewController = (segue.destination as? TutorialSummaryViewController)!
                vc.path = self.htmlPath
            }
        default:
            break
        }
    }
}

class FirstLoginViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func firstLogin() {
        let uuid = UUID().uuidString
        _ = AppDelegate().saveKeyChain(str: uuid, key: "userId")
        AppDelegate().httpRequest(route: "first_login", postBodyStr: "uuid=\(uuid)&lesson_completed=0")
        self.performSegue(withIdentifier: "toOption", sender: nil)
    }
    
    @IBAction func transferLogin() {
        let ac = UIAlertController(title: "引き継ぎコードを入力してください", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: {[weak ac] (action) -> Void in
            guard let textFields = ac?.textFields else {return}
            guard !textFields.isEmpty else {return}
            _ = AppDelegate().httpRequest(route: "transfer", postBodyStr: "uuid=\(UUID().uuidString)&transfer_id=\(textFields[0].text!)", calledBy: self, callTag: 2)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        ac.addTextField(configurationHandler: nil)
        ac.addAction(ok)
        ac.addAction(cancel)
        present(ac, animated: true, completion: nil)
    }
    
    func getTransferResult(result: String) {
        switch result {
        case "Query Failed":
            let alert = UIAlertController(title: "引き継ぎコードが間違っています", message: nil, preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        default:
            self.performSegue(withIdentifier: "toOption", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "toOption":
            let vc = (segue.destination as? OptionSelectViewController)!
            vc.isFirstLaunch = true
        default:
            break
        }
    }
}
