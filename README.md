# HKLSynthesizer

Audio Synthesizer & Sequencer for iOS.

# How to use

- `import HKLSynthesizer` (if you use Objective-C, import AudioEngineIF.h)
- Instantiate a AudioEngineIF object and use it.

```swift
let engine_ = AudioEngineIF()
```

# Methods

- `start()` starts synthesizer
- `stop()` stops running
- `tempo` property sets its bpm
- `numSteps` property decides the total steps of sequencer
- `sounds` property sets the sound file for each track.
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
@property (nonatomic, copy) NSArray<NSString*> *sounds;

/**
*  Set sequence for the specified track.
*
*  The sequence contains NSNumber<bool> values. The size must be equal to numSteps property.
*
*  @param sequence array of bool values. true means note on.
*  @param trackNo  track number
*/
- (void)setStepSequence:(NSArray<NSNumber *> *)sequence ofTrack:(NSInteger)trackNo;

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
*  Start playing
*/
- (void)start;

/**
*  Stop playing
*/
- (void)stop;

/**
*  Delegate object conforms to AudioEngineIFProtocol
*/
@property (nonatomic, weak) id<AudioEngineIFProtocol> delegate;
@end

@protocol AudioEngineIFProtocol <NSObject>
@required
- (void)audioEngine:(AudioEngineIF *)engine didTriggeredTrack:(int) trackNo step:(int)stepNo atTime:(uint64_t)absoluteTime;
@end
```
# Screenshot of sample project

![screenshot](images/screenshot_0.png)

# License

New BSD License

# Reference

This library uses [the sample program](https://code.google.com/p/korg-wist-sdk/) of [KORG WIST SDK](http://www.korguser.net/wist/) as audio engine.
