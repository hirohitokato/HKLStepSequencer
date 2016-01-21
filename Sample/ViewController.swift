//
//  ViewController.swift
//  Sample
//
//  Created by 加藤寛人 on 2016/01/09.
//  Copyright © 2016年 Hirohito Kato. All rights reserved.
//

import UIKit
import KSLSynthesizer

class ViewController: UIViewController {

    @IBOutlet weak var _bpmLabel: UILabel!
    @IBOutlet weak var _bpmSlider: UISlider!

    @IBOutlet weak var _stepLabel: UILabel!
    @IBOutlet weak var _stepSlider: UISlider!

    let BPM_MIN = 30.0
    let BPM_MAX = 300.0

    let engine_ = AudioEngineIF()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        bpmSliderUpdated(_bpmSlider)
        stepSliderUpdated(_stepSlider)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
    }
}

extension ViewController {

    @IBAction func setSounds(sender: AnyObject) {
        engine_.sounds = ["kick.wav", "snare.wav", "zap.wav", "noiz.wav"]
    }

    @IBAction func Start(sender: AnyObject) {
        engine_.start()
    }

    @IBAction func Stop(sender: AnyObject) {
        engine_.stop()
    }

    @IBAction func panSliderUpdated(sender: UISlider) {
        engine_.setPanPosition(Double(sender.value)*2.0-1, ofTrack: sender.tag)
    }

    @IBAction func ampSliderUpdated(sender: UISlider) {
        engine_.setAmpGain(Double(sender.value)*2.0, ofTrack: sender.tag)
    }

    @IBAction func bpmSliderUpdated(sender: UISlider) {
        let newBpm = (BPM_MAX * Double(sender.value)) + BPM_MIN
        engine_.tempo = newBpm
        _bpmLabel.text = String(newBpm)
    }
    @IBAction func stepSliderUpdated(sender: UISlider) {
        let numStep = Int(sender.value)
        engine_.numSteps = numStep
        _stepLabel.text = String(numStep)
    }
}

extension ViewController: AudioEngineIFProtocol {
    func audioEngine(engine: AudioEngineIF!,
        didTriggeredTrack trackNo: Int32,
        step stepNo: Int32,
        atTime absoluteTime: UInt64)
    {
        dispatch_async(dispatch_get_main_queue()) {

        }
    }
}