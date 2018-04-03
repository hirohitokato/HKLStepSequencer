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

    let _engine = HKLSynthesizer(numOfTracks: 4, numOfSteps: 12, stepsPerBeat: 12)

    override func viewDidLoad() {
        super.viewDidLoad()

        bpmSliderUpdated(_bpmSlider)
        stepSliderUpdated(_stepSlider)

        _engine.onTriggerdCallback = {
            (tracks: [Int], stepNo: Int, absoluteTime: UInt64) in
            print("\(absoluteTime): <\(stepNo)> \(tracks)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
    }
}

extension ViewController {

    @IBAction func setSounds(_ sender: Any) {
        _engine.sounds = ["kick.wav", "snare.wav", "zap.wav", "noiz.wav"]
    }

    @IBAction func resetSequence(_ sender: Any) {
        var track0 = [Bool](repeating: false, count: _engine.numberOfSteps)
        var track1 = [Bool](repeating: false, count: _engine.numberOfSteps)
        var track2 = [Bool](repeating: false, count: _engine.numberOfSteps)
        var track3 = [Bool](repeating: false, count: _engine.numberOfSteps)

        for i in 0 ..< _engine.numberOfSteps {
            track0[i] = ((i % 4) == 0) // kick
            track1[i] = ((i % 3) == 0) // snare
            track2[i] = ((i % 2) == 0) // zap
            track3[i] = ((i % 1) == 0) // noiz
        }
        _engine.setStepSequence(track0, ofTrack: 0)
        _engine.setStepSequence(track1, ofTrack: 1)
        _engine.setStepSequence(track2, ofTrack: 2)
        _engine.setStepSequence(track3, ofTrack: 3)
    }

    @IBAction func Start(_ sender: Any) {
        _engine.start()
    }

    @IBAction func Stop(_ sender: Any) {
        _engine.stop()
    }

    @IBAction func panSliderUpdated(_ sender: UISlider) {
        _engine.setPanPosition(Double(sender.value)*2.0-1, ofTrack: sender.tag)
    }

    @IBAction func ampSliderUpdated(_ sender: UISlider) {
        _engine.setAmpGain(Double(sender.value)*2.0, ofTrack: sender.tag)
    }

    @IBAction func bpmSliderUpdated(_ sender: UISlider) {
        let newBpm = (BPM_MAX * Double(sender.value)) + BPM_MIN
        _engine.tempo = newBpm
        _bpmLabel.text = String(newBpm)
    }
    @IBAction func stepSliderUpdated(_ sender: UISlider) {
        let numStep = Int(sender.value)
        _engine.numberOfSteps = numStep
        _stepLabel.text = String(numStep)
    }
}

