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
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(localeIdentifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    // MARK: UIViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
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
        if audioEngine.isRunning {
            self.audioEngine.stop()
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
        
        guard let inputNode = self.audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = self.recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            self.handleResult(result: result, error: error, inputnode: inputNode)
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        self.audioEngine.prepare()
        try self.audioEngine.start()
    }
    

    
    @IBAction func playAudio(_ sender: UIButton) {
        if let path = Bundle.main.urlForResource("test", withExtension: "m4a") {
            let recognizer = SFSpeechRecognizer()
            let request = SFSpeechURLRecognitionRequest(url: path)
            recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
                self.handleResult(result: result, error: error, inputnode: nil)
            })
        }
    }
    
    //MARK: Result handler
    func handleResult(result: SFSpeechRecognitionResult?, error: NSError?, inputnode: AVAudioInputNode?) {
        var isFinal = false
        
        if let result = result {
            self.textView.text = result.bestTranscription.formattedString
            isFinal = result.isFinal
            if isFinal == true {
                self.statusLabel.text = "Silence..."
            } else {
                self.statusLabel.text = "Listening..."
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
