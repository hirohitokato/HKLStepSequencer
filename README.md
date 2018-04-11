# HKLStepSequencer
<a href="https://developer.apple.com/"><img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" /></a>
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Swift_4-compatible-4BC51D.svg?style=flat" alt="Swift 4 compatible" /></a>
<a href="https://cocoapods.org/pods/HKLStepSequencer"><img src="https://img.shields.io/badge/pod-0.9.0-blue.svg" alt="CocoaPods compatible" /></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>
<a href="https://raw.githubusercontent.com/hirohitokato/HKLStepSequencer/master/LICENSE"><img src="http://img.shields.io/badge/license-NewBSD-blue.svg?style=flat" alt="License: New BSD" /></a>

Audio synthesizer & sequencer engine for iOS. It enables you to create a rhythmbox/drum-machine app easily.

# Features

- M tracks & N steps sequencer.(depends on your iOS device spec)
- gain & pan parameters for each track
- supports 44100Hz/16bits linearPCM audio data
- supports over 1000bpm(actually, there is no limit)

# How to use

- Instantiate a HKLStepSequencer object and use it. 

```swift
import HKLStepSequencer

// 1. Create 16steps x 4tracks synthesizer
let engine = HKLStepSequencer(numOfTracks: 4, numOfSteps: 16)
engine.tempo = 120

// 2. Load sounds
engine.sounds = ["kick.wav", "snare.wav", "zap.wav", "noiz.wav"]

// 3. Set step sequences
var track0 = [Bool](repeating: false, count: engine.numberOfSteps)
var track1 = [Bool](repeating: false, count: engine.numberOfSteps)
var track2 = [Bool](repeating: false, count: engine.numberOfSteps)
var track3 = [Bool](repeating: false, count: engine.numberOfSteps)

for i in 0 ..< engine.numberOfSteps {
    track0[i] = ((i % 4) == 0) // kick
    track1[i] = ((i % 3) == 0) // snare
    track2[i] = ((i % 2) == 0) // zap
    track3[i] = ((i % 1) == 0) // noiz
}
engine.setStepSequence(track0, ofTrack: 0)
engine.setStepSequence(track1, ofTrack: 1)
engine.setStepSequence(track2, ofTrack: 2)
engine.setStepSequence(track3, ofTrack: 3)

// 4. Start playing
engine.start()
```

- Can change each track's pan position & gain

```swift
// track0: left, track1: right, other: center(0.0)
engine.setPanPosition(-1.0/*left*/,  ofTrack: 0)
engine.setPanPosition( 1.0/*right*/, ofTrack: 1)

// track2 gain: x2.0(0.0-2.0)
engine.setAmpGain(2.0, ofTrack: 2)
```

# Methods

- `start()` starts synthesizer
- `stop()` stops running
- `tempo` property sets its bpm
- `numSteps` property decides total steps of the sequencer
- `sounds` property sets a sound file names for each track.
- `setStepSequence()` sets a note on/off sequence for the specified track.
- `setAmpGain()` sets an amp gain for the specified track.
- `setPanPosition()` sets a panning position for the specified track.

The class API is as follows:

```swift
@protocol AudioEngineIFProtocol;

@interface AudioEngineIF : NSObject

/**
*  bpm
*/
@property (nonatomic, assign) double tempo;

/**
*  number of steps in a track
*/
@property (nonatomic, assign) NSInteger numSteps;

/**
*  Sound files. The number of sounds must be equal to the number of tracks
*/
@property (nonatomic, copy) NSArray<NSString*>* _Nullable sounds;

/**
*  Set sequence for the specified track.
*
*  The sequence contains NSNumber<bool> values. The size must be equal to numSteps property.
*
*  @param sequence array of bool values. true means note on.
*  @param trackNo  track number
*/
- (void)setStepSequence:(NSArray<NSNumber *>* _Nonnull)sequence ofTrack:(NSInteger)trackNo;

/**
*  Set amplifier gain(0.0-2.0) for the specified track
*
*  @param ampGain 0.0(mute)…1.0(original)…2.0(x2.0)
*  @param trackNo track number
*/
- (void)setAmpGain:(double)ampGain ofTrack:(NSInteger)trackNo;

/**
*  Set pan position(-1.0…1.0) for the specified track.
*
*  @param position -1.0(left)…0.0(center)…1.0(right)
*  @param trackNo  track number
*/
- (void)setPanPosition:(double)position ofTrack:(NSInteger)trackNo;

/**
*  Start a sequencer
*/
- (void)start;

/**
*  Stop a sequencer
*/
- (void)stop;

/**
*  Delegate object conforms to AudioEngineIFProtocol
*/
@property (nonatomic, weak) id<AudioEngineIFProtocol> delegate;
@end

@protocol AudioEngineIFProtocol <NSObject>
@required
/**
*  Tells the delegate that the sequencer has triggered at the step(time)
*
*  @param engine       the audio engine that the tracks are triggered
*  @param tracks       tracks that the note is ON
*  @param stepNo       step number
*  @param absoluteTime time for triggered
*/
- (void)audioEngine:(AudioEngineIF * _Nonnull)engine didTriggeredTracks:(NSArray<NSNumber *>* _Nonnull) tracks step:(int)stepNo atTime:(uint64_t)absoluteTime;
@end
```
# Screenshots of sample project

The sample shows 4 track & N steps sequencer.

![screenshot](images/screenshot_0.png)

# License

New BSD License

# Reference

This library uses [the sample program](https://code.google.com/p/korg-wist-sdk/) of [KORG WIST SDK](http://www.korguser.net/wist/) as audio engine.
