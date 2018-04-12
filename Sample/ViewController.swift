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
    var _sequences = [[Bool]]()

    let BPM_MIN = 30.0
    let BPM_MAX = 300.0

    let _engine = HKLStepSequencer(numOfTracks: 4, numOfSteps: 8)

    override func viewDidLoad() {
        super.viewDidLoad()

        bpmSliderUpdated(_bpmSlider)
        stepSliderUpdated(_stepSlider)

        resetSequence(self)
        setupTrackUI()

        var info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        let numer = UInt64(info.numer)
        let denom = UInt64(info.denom)

        _engine.onTriggerdCallback = {
            [weak self] (tracks: [Int], stepNo: Int, absoluteTime: UInt64) in
            let t_ns = ((absoluteTime - mach_absolute_time()) * numer) / denom
            let t_sec = Double(t_ns) / 1_000_000_000
            print("<\(stepNo)> \(tracks) will fire after \(t_sec)sec")

            DispatchQueue.main.asyncAfter(deadline: .now() + t_sec) {
                self?.blink(step: stepNo)
            }
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
            track.arrangedSubviews.forEach {
                $0.removeFromSuperview()
            }

            for j in 0..<_engine.numberOfSteps {
                let button = UIButton(type: .custom)

                button.tag = i * 100 + j
                button.backgroundColor = .white
                button.layer.borderColor = UIColor.gray.cgColor
                button.layer.borderWidth = 1
                button.layer.cornerRadius = 4
                button.addTarget(self, action: #selector(stepButtonTapped(_:)), for: .touchDown)

                track.addArrangedSubview(button)
            }
        }
    }
}

extension ViewController {

    @IBAction func setSounds(_ sender: Any) {
        _engine.sounds = ["kick.wav", "snare.wav", "zap.wav", "noiz.wav"]
    }

    @IBAction func resetSequence(_ sender: Any) {

        _sequences.removeAll()

        for i in 0..<_engine.numberOfTracks {
            let sequence = [Bool](repeating: false, count: _engine.numberOfSteps)

            _sequences.append(sequence)
            _engine.setStepSequence(sequence, ofTrack: i)
        }
    }

    @objc public func stepButtonTapped(_ sender: UIButton) {
        let track = sender.tag / 100
        let step = sender.tag % 100

        _sequences[track][step] = !_sequences[track][step]
        sender.backgroundColor = _sequences[track][step] ? .red : .white

        _engine.setStepSequence(_sequences[track], ofTrack: track)
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
        _bpmLabel.text = String(Int(newBpm))
    }
    @IBAction func stepSliderUpdated(_ sender: UISlider) {
        let numStep = Int(sender.value)
        _engine.numberOfSteps = numStep
        _stepLabel.text = String(numStep)

        resetSequence(self)
        setupTrackUI()
    }

    private func blink(step: Int) {
        _tracks.forEach {
            $0.arrangedSubviews
                .filter { $0.tag % 100 == step }
                .forEach { button in
                    let animation = CABasicAnimation(keyPath: "borderWidth")
                    animation.duration = 0.3
                    animation.repeatCount = 0
                    animation.fromValue = 3
                    animation.toValue = 1
                    button.layer.add(animation, forKey: "borderWidth")
            }
        }
    }
}

