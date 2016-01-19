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
 *  the number of steps in a track
 */
@property (nonatomic, assign) NSInteger numSteps;

/**
 *  Sound files. The number of sounds must be equal to the number of tracks
 */
@property (nonatomic, copy) NSArray<NSString*> *sounds;

/**
 *  Delegate object conforms to AudioEngineIFProtocol
 */
@property (nonatomic, weak) id<AudioEngineIFProtocol> delegate;

/**
 *  Start sequencer
 */
- (void)start;
/**
 *  Stop sequencer
 */
- (void)stop;

/**
 *  returns current time by mach_absolute_time()
 *  @return current time
 */
- (uint64_t)now;
@end

@protocol AudioEngineIFProtocol <NSObject>
@required
- (void)audioEngine:(AudioEngineIF *)engine didTriggeredTrack:(int) trackNo step:(int)stepNo atTime:(uint64_t)absoluteTime;
@end
