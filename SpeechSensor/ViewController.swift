//
//  ViewController.swift
//  SpeechSensor
//
//  Created by Debaprio Banik on 7/20/16.
//  Copyright © 2016 Debaprio Banik. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        let tranVC = segue.destinationViewController as! TranscriptViewController
        
        if segue.identifier == "speak" {
            tranVC.isAudioPlay = false
        } else if segue.identifier == "audio" {
            tranVC.isAudioPlay = true
        }
    }
}

