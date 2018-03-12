//
//  BaseSpeechViewController.swift
//  Faith
//
//  Created by Pranav Karnani on 12/03/18.
//  Copyright © 2018 Pranav Karnani. All rights reserved.
//

import UIKit
import SpeechKitManager
import SwiftSiriWaveformView
import ApiAI
import AVFoundation
import Speech



class BaseSpeechViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    var data : [String] = []
    var loop : Int = 0
    
    @IBAction func happyTapped(_ sender: Any) {
        mySpokenText = "happy"
        happyOrSadView()
        decide()
        collectionTable.reloadData()
    }
    @IBAction func feelingSadTapped(_ sender: Any) {
        mySpokenText = "sad"
        happyOrSadView()
        decide()
        collectionTable.reloadData()
    }
    
    func decide() {
        loop = loop + 1
        if loop == 3 {
            loop = 0
        }
    }
    @IBOutlet weak var feelingHappy: UIButton!
    @IBOutlet weak var feelingSad: UIButton!
    var flag = 0
    var count = 0
    var change:CGFloat = 0.01
    var timer2:Timer?
    
    
    @IBOutlet weak var collectionTable: UICollectionView!
    @IBOutlet weak var jack: UIButton!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    let speechSynthesizer = AVSpeechSynthesizer()
    var toBespokenText : String = "Hey, I am Faith. I am here to help you."
    var mySpokenText : String = ""
    @IBOutlet weak var waveform: SwiftSiriWaveformView!
    @IBOutlet weak var myAnswer: UILabel!
    @IBOutlet weak var botAnswer: UILabel!
    
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    
    private var speechKitManager:SpeechKitManager?
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        settings()
        collectionTable.alpha = 0
        collectionTable.dataSource = self
        collectionTable.delegate = self
        speechKitManager = SpeechKitManager()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        speakfunc(self)
        speechKitManager?.requestSpeechRecognizerAuth({ authStatus in
            DispatchQueue.main.async {
//                self.collectionTable.setGradientBackground(colorOne: r1, colorTwo: r2)
                self.collectionTable.clipsToBounds = false
                OperationQueue.main.addOperation {
                    switch authStatus {
                    case .authorized:
                        print("requestSpeechRecognizerAuth authorized")
                    case .denied:
                        print("requestSpeechRecognizerAuth denied")
                    case .restricted:
                        print("requestSpeechRecognizerAuth restricted")
                    case .notDetermined:
                        print("requestSpeechRecognizerAuth notDetermined")
                    }
                }
            }
            
            self.toBespokenText = "Hello! I am Faith. I'm here to help."
            self.speaker()
        })
    }
    
    override func viewDidLayoutSubviews() {
        self.collectionTable.layer.cornerRadius = 16
        self.collectionTable.clipsToBounds = true
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped() {
        print(flag)
        if flag <= 1 {
            
            if flag == 0 {
                
                timer2 = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(ViewController.refreshAudioView(_:)), userInfo: nil, repeats: true)
            }
            authorizeMicAccess()
            count = count + 1
            flag = flag + 1
            happyOrSadView()
        }
        if flag == 2 {
            happyOrSadView()
            sendMessage()
            flag = 0
            timer2?.invalidate()
            waveform.amplitude = 0.3
        }
        
        if count == 5 {
            self.collectionTable.alpha = 1
            self.feelingSad.isUserInteractionEnabled = true
            self.feelingHappy.isUserInteractionEnabled = true
            self.feelingSad.alpha = 1
            self.feelingHappy.alpha = 1
            happyOrSadView()
        }
    }
    
    fileprivate func authorizeMicAccess(){
        speechKitManager?.requestMicAuth({ (granted) in
            if granted{
                //Mic access granted start recognition
                self.recognize()
            }else{
                debugPrint("Microphone permission required")
            }
        })
    }
    
    fileprivate func recognize(){
        speechKitManager?.record(resultHandler: { (result, error) in
            var isFinal = false
            
            if let result = result {
                //User speech will fall here to text
                debugPrint(result.bestTranscription.formattedString)
                isFinal = result.isFinal
                self.myAnswer.text = result.bestTranscription.formattedString
                self.mySpokenText = result.bestTranscription.formattedString
            }
            
            if error != nil || isFinal {
                self.speechKitManager?.stop()
            }
        })
    }
    
    @objc func sendMessage() {
        
        let request = ApiAI.shared().textRequest()
        
        request?.query = mySpokenText
        request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            if (response.result.fulfillment.speech) != nil {
                
                
                self.toBespokenText = response.result.fulfillment.speech
                self.botAnswer.text = self.toBespokenText
                
                func speak(_ phrases: [(phrase: String, wait: Double)]){
                    if let (phrase, wait) = phrases.first{
                        let speechUtterance = AVSpeechUtterance(string: spokenText)
                        speechUtterance.rate = 0.45
                        speechUtterance.pitchMultiplier = 1.0
                        speechUtterance.volume = 100
                        self.speechSynthesizer.speak(speechUtterance)
                        let rest = Array(phrases.dropFirst())
                        self.speaker()
                        
                    }
                }
                
                self.speaker()
                
                
            }
        }, failure: { (request, error) in
            print(error!)
        })
        
        ApiAI.shared().enqueue(request)
        
    }
    
    func happyOrSadView(){
        
        if mySpokenText.contains("happy") || mySpokenText.contains("joyful") || mySpokenText.contains("merry") || mySpokenText.contains("funny") || mySpokenText.contains("pleasant") || mySpokenText.contains("breezy") || mySpokenText.contains("feeling great")
        {
            feelingHappy.isUserInteractionEnabled = false
            feelingSad.isUserInteractionEnabled = false
            UIView.animate(withDuration: 1, animations: {
                self.view.backgroundColor = UIColor.white
                self.usernameLabel.textColor = UIColor.black
                self.myAnswer.textColor = UIColor.black
                self.botAnswer.textColor = UIColor.black
                self.logo.image = #imageLiteral(resourceName: "Group 2")
                self.jack.setImage(#imageLiteral(resourceName: "MicrophoneHappy"), for: .normal)
                self.waveform.backgroundColor = UIColor.clear
                
                
                
            }, completion: nil)
            
            
            
        }
        else if mySpokenText.contains("sad") || mySpokenText.contains("depressed") || mySpokenText.contains("low") || mySpokenText.contains("unhappy") || mySpokenText.contains("crying") || mySpokenText.contains("angry") || mySpokenText.contains("shit")
        {
            UIView.animate(withDuration: 1, animations: {
                self.view.backgroundColor = UIColor.black
                self.usernameLabel.textColor = UIColor.white
                self.botAnswer.textColor = UIColor.white
                self.myAnswer.textColor = UIColor.white
                self.logo.image = #imageLiteral(resourceName: "logo")
                self.jack.setImage(#imageLiteral(resourceName: "MicrophoneSad"), for: .normal)
                self.waveform.backgroundColor = UIColor.clear
                
            }, completion:  nil)
            
            
        }
        
        
    }
    
    
    func settings() {
        usernameLabel.text = "Hey \(username)"
        DataHandler.shared.persistData { (stat) in
            if stat {
                RequestHandler.shared.getQuotes(completion: { (stat1) in
                    if stat {
                        RequestHandler.shared.getPlaces(completion: { (stat2) in
                            if stat2 {
                                
                                RequestHandler.shared.getMusic(completion: { (stat3) in
                                    if stat3 {
                                        RequestHandler.shared.getRestaurants(completion: { (stat4) in
                                            if stat4 {
                                                DispatchQueue.main.async {
                                                    self.collectionTable.reloadData()
                                                }
                                            }
                                        })
                                    }
                                    
                                })
                            }
                        })
                    }
                })
                
            }
        }
    }
    @IBAction func speakfunc(_: AnyObject){
        
        happyOrSadView()
        
    }
    
    func speaker() {
        print(toBespokenText)
        
        //added new for audio on phone, not working
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            print("error1")
        }
        
        let speechUtterance = AVSpeechUtterance(string: toBespokenText)
        speechUtterance.rate = 0.47
        speechUtterance.pitchMultiplier = 1.2
        speechUtterance.volume = 100
        speechSynthesizer.speak(speechUtterance)
        
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()){
        
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    @objc internal func refreshAudioView(_:Timer) {
        if self.waveform.amplitude <= self.waveform.idleAmplitude || self.waveform.amplitude > 1.0 {
            self.change *= -1.0
        }
        
        // Simply set the amplitude to whatever you need and the view will update itself.
        self.waveform.amplitude += self.change
    }
    
}

extension BaseSpeechViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if loop == 1 {
            return places[0].mydata.count
        }
        
        else if  loop == 2 {
            return 2
        }
        else {
            return music.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCell", for: indexPath) as! CustomCollectionViewCell
        if loop == 1 {
            cell.songTitle.text = places[0].mydata[indexPath.row].name!
            cell.songArtist.text = places[0].mydata[indexPath.row].address!
        }
        else if loop == 2 {
            cell.songTitle.text = quotes.quote!
            cell.songArtist.text = quotes.author!
        }
            
        else {
//        cell.setGradientBackground(colorOne: r1, colorTwo: r2)
        cell.songArtist.text = music[indexPath.row].mydata[indexPath.row].artist!
        cell.songTitle.text = music[indexPath.row].mydata[indexPath.row].title!
        }
        
//        cell.cView.setGradientBackground(colorOne: r1, colorTwo: r2)
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if loop == 0 {
            let url = music[indexPath.row].mydata[indexPath.row].preview!
            play(url : url)
        }
    }
    
    
    func play(url: String) {
        print("playing \(url)")
        
        let url = URL(string: url)
        let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
        player = AVPlayer(playerItem: playerItem)
        player!.play()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsetsMake(0, 5, 0, 5)
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width-10, height: collectionView.frame.height-10)
    }
    
    
    
}

