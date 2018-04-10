//
//  HKLSynthesizer.swift
//  HKLSynthesizer
//
//  Created by Hirohito Kato on 2018/03/31.
//  Copyright 2018 Hirohito Kato. All rights reserved.
//

import Foundation

public class HKLSynthesizer: NSObject {
    /// callbacks from the audio engine to tell that the sequencer has triggered at the step(time).
    ///
    /// - Parameters:
    ///   - tracks: an array of tracks that the note is now ON
    ///   - stepNo: the index of current step
    ///   - absoluteTime: host time when the note is triggered
    public typealias TriggerdCallback = (_ tracks: [Int], _ stepNo: Int, _ absoluteTime: UInt64) -> ()

    /// callbacks from the audio engine to tell that the sequencer has triggered at the step(time).
    ///
    /// - Parameters:
    ///   - tracks: an array of tracks that the note is now ON
    ///   - stepNo: the index of current step
    ///   - absoluteTime: host time when the note is triggered
    public var onTriggerdCallback: TriggerdCallback?

    private let engine_: AudioEngineIF

    private override init() {
        fatalError("Unable to initialize HKLSynthesizer with init()")
    }

    /// Instantiate a object and initialize it.
    ///
    /// - Parameters:
    ///   - numOfTracks: The number of tracks the sequencer has
    ///   - numOfSteps: The number of steps in a track
    ///   - stepsPerBeat: The number of steps in one beat
    public init(numOfTracks: Int, numOfSteps: Int, stepsPerBeat: Int=1) {
        engine_ = AudioEngineIF(numOfTracks: Int32(numOfTracks),
                                numOfSteps: Int32(numOfSteps),
                                stepsPerBeat: Int32(stepsPerBeat))

        super.init()
        engine_.delegate = self
    }

    /// bpm
    public var tempo: Double {
        get { return engine_.tempo }
        set { engine_.tempo = newValue }
    }

    /// number of tracks the sequencer has
    public var numberOfTracks: Int {
        get { return engine_.numTracks }
        set { engine_.numTracks = newValue }
    }

    /// number of steps in a track
    public var numberOfSteps: Int {
        get { return engine_.numSteps }
        set { engine_.numSteps = newValue }
    }

    ///  Sound files for each track. The number of sounds must be equal to the number of tracks
    public var sounds: [String]? {
        get { return engine_.sounds }
        set { engine_.sounds = newValue }
    }

    /// Set sequence for the specified track.
    ///
    /// The sequence contains NSNumber<bool> values. The size must be equal to numSteps property.
    ///
    /// - Parameters:
    ///   - sequence: an array of bool values. true means note on.
    ///   - trackNo: target track number
    public func setStepSequence(_ sequence: [Bool], ofTrack trackNo: Int) {
        let seq = sequence.map{ NSNumber(value: $0) }
        engine_.setStepSequence(seq, ofTrack: trackNo)
    }

    /// Erase all notes(ON/OFF) of the specified track
    ///
    /// - Parameter trackNo: target track number
    public func clearSequence(ofTrackNo trackNo: Int) {
        engine_.clearSequence(trackNo)
    }

    /// Set amplifier gain(0.0-2.0) for the specified track
    ///
    /// - Parameters:
    ///   - ampGain: 0.0(mute)…1.0(as is)…2.0(x2.0)
    ///   - trackNo: target track number
    public func setAmpGain(_ ampGain: Double, ofTrack trackNo: Int) {
        engine_.setAmpGain(ampGain, ofTrack: trackNo)
    }

    /// Set pan position(-1.0…1.0) for the specified track.
    ///
    /// - Parameters:
    ///   - position: -1.0(left)…0.0(center)…1.0(right)
    ///   - trackNo: target track number
    public func setPanPosition(_ position: Double, ofTrack trackNo: Int) {
        engine_.setPanPosition(position, ofTrack: trackNo)
    }

    /// Start the sequencer
    public func start() {
        engine_.start()
    }

    /// Stop the sequencer
    public func stop() {
        engine_.stop()
    }
}

extension HKLSynthesizer: AudioEngineIFProtocol {
    public func audioEngine(_ engine: AudioEngineIF, willTriggerTracks tracks: [NSNumber], step stepNo: Int32, atTime absoluteTime: UInt64) {
        guard let callback = onTriggerdCallback else { return }

        let intStepNo = Int(stepNo)
        let intTracks = tracks.flatMap { return $0.intValue }
        callback(intTracks, intStepNo, absoluteTime)
    }
}
