# KSLSynthesizer

Audio Synthesizer & Sequencer for iOS

# How to use

- `import KSLSynthesizer` (if you use Objective-C, import AudioEngineIF.h)
- Instantiate a AudioEngineIF object

```swift
let engine_ = AudioEngineIF()
```

# Methods

- `start()` starts synthesizer
- `stop()` stops running
- `tempo` property specifies its bpm
- `numSteps` property decides the total steps of sequencer
- `sounds` property sets the sound set. The number of files must be equal with the number of tracks

The class API is as follows:

```swift
@protocol AudioEngineIFProtocol;

@interface AudioEngineIF : NSObject

@property (nonatomic, assign) double tempo;
@property (nonatomic, assign) NSInteger numSteps;
@property (nonatomic, copy) NSArray<NSString*> *sounds;
@property (nonatomic, weak) id<AudioEngineIFProtocol> delegate;

- (void)start;
- (void)stop;
@end

@protocol AudioEngineIFProtocol <NSObject>
@required
- (void)audioEngine:(AudioEngineIF *)engine didTriggeredTrack:(int) trackNo step:(int)stepNo atTime:(uint64_t)absoluteTime;
@end
```

# License

New BSD License

# Reference

This library uses [the sample program](https://code.google.com/p/korg-wist-sdk/) of [KORG WIST SDK](http://www.korguser.net/wist/).
