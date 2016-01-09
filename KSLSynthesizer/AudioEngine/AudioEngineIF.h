//
//  AudioEngineIF.h
//
//  Created by Hirohito Kato on 2016/01/08.
//  Copyright © 2016 Hirohito Kato. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioEngineIF : NSObject

@property (nonatomic, assign) float tempo;

- (void)start;
- (void)stop;

/**
 *  returns current time by mach_absolute_time()
 *  @return current time
 */
- (uint64_t)now;
@end
