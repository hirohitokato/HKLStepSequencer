//
//  ViewController.swift
//  Sample
//
//  Created by Hirohito Kato on 2016/01/09.
//  Copyright © 2016年 Hirohito Kato. All rights reserved.
//

import UIKit
import HKLStepSequencer

class ViewController: UIViewController {

    @IBOutlet weak var _bpmLabel: UILabel!
    @IBOutlet weak var _bpmSlider: UISlider!

    @IBOutlet weak var _stepLabel: UILabel!
    @IBOutlet weak var _stepSlider: UISlider!

    @IBOutlet var _tracks: [UIStackView]!
    var _notes = [[Bool]]()

    let BPM_MIN = 30.0
    let BPM_MAX = 300.0

    let _engine = HKLStepSequencer(numOfTracks: 4, numOfSteps: 8)

    override func viewDidLoad() {
        super.viewDidLoad()

        bpmSliderUpdated(_bpmSlider)
        stepSliderUpdated(_stepSlider)

        setupTrackUI()

        var info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        let numer = UInt64(info.numer)
        let denom = UInt64(info.denom)

        _engine.onTriggerdCallback = {
            (tracks: [Int], stepNo: Int, absoluteTime: UInt64) in
            let t_ns = ((absoluteTime - mach_absolute_time()) * numer) / denom
            let t_sec = Double(t_ns) / 1_000_000_000
            print("<\(stepNo)> \(tracks) will fire after \(t_sec)sec")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
    }

    private func setupTrackUI() {
        for (i, track) in _tracks.enumerated() {
            let trackNotes = [Bool](repeating: false, count: 8)
            _notes.append(trackNotes)

            for j in 0..<8 {
                let button = UIButton(type: .custom)
                button.tag = i * 100 + j
                button.backgroundColor = .white
                button.layer.borderColor = UIColor.gray.cgColor
                button.layer.borderWidth = 1
                button.layer.cornerRadius = 4
                button.addTarget(self, action: #selector(tappedButton(_:)), for: .touchDown)
                track.addArrangedSubview(button)
            }
        }
    }
    @objc public func tappedButton(_ sender: UIButton) {
        let track = sender.tag / 100
        let step = sender.tag % 100

        _notes[track][step] = !_notes[track][step]
        sender.backgroundColor = _notes[track][step] ? .red : .white

        _engine.setStepSequence(_notes[track], ofTrack: track)
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

