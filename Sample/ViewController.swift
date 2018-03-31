//
//  ViewController.swift
//  Sample
//
//  Created by Hirohito Kato on 2016/01/09.
//  Copyright © 2016年 Hirohito Kato. All rights reserved.
//

import UIKit
import HKLSynthesizer

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

        engine_.delegate = self

        bpmSliderUpdated(_bpmSlider)
        stepSliderUpdated(_stepSlider)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
    }
}

extension Array where Element == Bool {
    var nsArray: [NSNumber] {
        return self.map{ NSNumber(value:$0) }
    }
}

extension ViewController {

    @IBAction func setSounds(_ sender: AnyObject) {
        engine_.sounds = ["kick.wav", "snare.wav", "zap.wav", "noiz.wav"]
    }

    @IBAction func resetSequence(_ sender: AnyObject) {
        var track0 = [Bool](repeating: false, count: engine_.numSteps)
        var track1 = [Bool](repeating: false, count: engine_.numSteps)
        var track2 = [Bool](repeating: false, count: engine_.numSteps)
        var track3 = [Bool](repeating: false, count: engine_.numSteps)

        for i in 0 ..< engine_.numSteps {
            track0[i] = ((i % 4) == 0)
            track1[i] = ((i % 8) == 0)
            track2[i] = ((i % 2) == 0)
            track3[i] = ((i % 1) == 0)
        }
        engine_.setStepSequence(track0.nsArray, ofTrack: 0)
        engine_.setStepSequence(track1.nsArray, ofTrack: 1)
        engine_.setStepSequence(track2.nsArray, ofTrack: 2)
        engine_.setStepSequence(track3.nsArray, ofTrack: 3)
    }

    @IBAction func Start(_ sender: AnyObject) {
        engine_.start()
    }

    @IBAction func Stop(_ sender: AnyObject) {
        engine_.stop()
    }

    @IBAction func panSliderUpdated(_ sender: UISlider) {
        engine_.setPanPosition(Double(sender.value)*2.0-1, ofTrack: sender.tag)
    }

    @IBAction func ampSliderUpdated(_ sender: UISlider) {
        engine_.setAmpGain(Double(sender.value)*2.0, ofTrack: sender.tag)
    }

    @IBAction func bpmSliderUpdated(_ sender: UISlider) {
        let newBpm = (BPM_MAX * Double(sender.value)) + BPM_MIN
        engine_.tempo = newBpm
        _bpmLabel.text = String(newBpm)
    }
    @IBAction func stepSliderUpdated(_ sender: UISlider) {
        let numStep = Int(sender.value)
        engine_.numSteps = numStep
        _stepLabel.text = String(numStep)
    }
}

extension ViewController: AudioEngineIFProtocol {
    func audioEngine(_ engine: AudioEngineIF,
        didTriggeredTracks tracks: [NSNumber],
        step stepNo: Int32,
        atTime absoluteTime: UInt64)
    {
        print("\(tracks)")
        DispatchQueue.main.async {
        }
    }
}
