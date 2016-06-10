//
//  AudioEngineIF.h
//
//  Created by Hirohito Kato on 2016/01/08.
//  Copyright © 2016 Hirohito Kato. All rights reserved.
//

#import <Foundation/Foundation.h>

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
 *  Erase all individual status of the specified track
 *
 *  @param trackNo track number
 */
- (void)clearSequence:(NSInteger)trackNo;

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
@property (nonatomic, weak) id<AudioEngineIFProtocol> _Nullable delegate;
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
