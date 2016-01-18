//
//  AudioEngineIF.h
//
//  Created by Hirohito Kato on 2016/01/08.
//  Copyright © 2016 Hirohito Kato. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioEngineIFProtocol;

@interface AudioEngineIF : NSObject

@property (nonatomic, assign) double tempo;
@property (nonatomic, assign) NSInteger numSteps;
@property (nonatomic, copy) NSArray<NSString*> *sounds;
@property (nonatomic, weak) id<AudioEngineIFProtocol> delegate;

- (void)start;
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
