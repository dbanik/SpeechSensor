//
//  TranscriptViewController.swift
//  SpeechSensor
//
//  Created by Debaprio Banik on 7/20/16.
//  Copyright © 2016 Debaprio Banik. All rights reserved.
//

import Foundation
import UIKit
import Speech

public class TranscriptViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: Properties
    
    public var isAudioPlay = false
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(localeIdentifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var timer: Timer?
    
    var counter = 0
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var warningLabel: UILabel!
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.statusLabel.text = ""
        self.warningLabel.text = ""
        if self.isAudioPlay == true {
            self.startButton.isHidden = true
            self.playButton.isHidden = false
        } else {
            self.playButton.isHidden = true
            self.startButton.isHidden = false
        }
        
        // Disable the start button until authorization has been granted.
        self.startButton.isEnabled = false
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.startButton.isEnabled = true
                    
                case .denied:
                    self.startButton.isEnabled = false
                    self.startButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.startButton.isEnabled = false
                    self.startButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.startButton.isEnabled = false
                    self.startButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.startButton.isEnabled = true
            self.startButton.setTitle("Start Recording", for: [])
        } else {
            self.startButton.isEnabled = false
            self.startButton.setTitle("Recognition not available", for: .disabled)
        }
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func start(_ sender: UIButton) {
        if self.audioEngine.isRunning {
            audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.startButton.isEnabled = false
            self.startButton.setTitle("Stopping", for: .disabled)
        } else {
            try! startTranscription()
            self.startButton.setTitle("Stop recording", for: [])
        }
    }
    
    private func startTranscription() throws {
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = self.recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        if let timer = self.timer {
            timer.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TranscriptViewController.update), userInfo: nil, repeats: true)
        
        recognitionTask = self.speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            self.handleResult(result: result, error: error, inputnode: inputNode)
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        self.audioEngine.prepare()
        try self.audioEngine.start()
    }
    
    func update() {
        self.counter+=1
        OperationQueue.main.addOperation {
            self.statusLabel.text = String(self.counter)
            if self.counter > 15 {
                self.warningLabel.text = "Long silence..."
            } else if self.counter > 25 {
                self.warningLabel.text = "Ver long silence !!"
            } else {
                self.warningLabel.text = ""
            }
        }
    }

    
    @IBAction func playAudio(_ sender: UIButton) {
        if let path = Bundle.main.urlForResource("test", withExtension: "m4a") {
            let recognizer = SFSpeechRecognizer()
            let request = SFSpeechURLRecognitionRequest(url: path)
            if let timer = self.timer {
                timer.invalidate()
            }
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(TranscriptViewController.update), userInfo: nil, repeats: true)
            
            recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
                self.handleResult(result: result, error: error, inputnode: nil)
            })
        }
    }
    
    //MARK: Result handler
    
    func handleResult(result: SFSpeechRecognitionResult?, error: NSError?, inputnode: AVAudioInputNode?) {
        var isFinal = false
        self.counter = 0
        if let result = result {
            OperationQueue.main.addOperation {
                self.statusLabel.text = "Silence..."
                self.textView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                if isFinal == true {
                    self.statusLabel.text = "Finished."
                } else {
                    self.statusLabel.text = ""
                }
            }
        }
        
        if error != nil || isFinal {
            self.audioEngine.stop()
            if inputnode != nil {
                inputnode?.removeTap(onBus: 0)
            }
            
            self.recognitionRequest = nil
            self.recognitionTask = nil
            self.textView.text = "Unable to receive speech"
            self.statusLabel.text = "Error"
            self.startButton.isEnabled = true
            self.startButton.setTitle("Start Recording", for: [])
        }
    }
}
