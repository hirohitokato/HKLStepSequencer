//
//  AudioEngineIF.mm
//
//  Created by Hirohito Kato on 2016/01/08.
//  Copyright © 2016 Hirohito Kato. All rights reserved.
//

#import <mach/mach_time.h>
#import "AudioEngineIF.h"
#import "AudioIO.h"
#import "Synthesizer.h"

class SequencerConnector : public SequencerListener {
    AudioEngineIF *receiver_;
public:
    SequencerConnector(AudioEngineIF *receiver) : receiver_(receiver) {}
    void NoteOnViaSequencer(int frame, int partNo, int step) {
        NSLog(@"frame:%d partNo:%d step:%d", frame, partNo, step);
        dispatch_async(dispatch_get_main_queue(), ^{
            //[receiver_ blinkUIWithPart:partNo step:step];
        });
    }
};

@interface AudioEngineIF ()
@property (nonatomic) Synthesizer*        synth;
@property (nonatomic) AudioIO*            audioIo;
@property (nonatomic) SequencerConnector* connector;
@end

@implementation AudioEngineIF

//  ---------------------------------------------------------------------------
//      initWithNibName:bundle
//  ---------------------------------------------------------------------------
- (id)init
{
    self = [super init];
    if (self != nil)
    {
        self.tempo = 120.0f;

        const float fs = 44100.0f;
        _synth = new Synthesizer(fs);
        _audioIo = new AudioIO(fs);
        _connector = new SequencerConnector(self);
        _synth->GetSequencer()->AddListener(_connector);
        _audioIo->SetListener(_synth);
        _audioIo->Open();
        _audioIo->Start();
    }
    return self;
}

//  ---------------------------------------------------------------------------
//      dealloc
//  ---------------------------------------------------------------------------
- (void)dealloc
{
    delete _audioIo;
    _audioIo = NULL;
    delete _synth;
    _synth = NULL;
    delete _connector;
    _connector = NULL;
}

#pragma mark -

//  ---------------------------------------------------------------------------
//      latency
//  ---------------------------------------------------------------------------
- (uint64_t)latency
{
    uint64_t    result = 0;
    if (_audioIo != NULL)
    {
        result += _audioIo->GetLatency();  //  audio i/o latency
    }
    return result;  //  nanosec
}

#pragma mark public property & methods
//  ---------------------------------------------------------------------------
//      setTempo
//  ---------------------------------------------------------------------------
- (void)setTempo:(float)tempo
{
    _tempo = static_cast<float>(static_cast<int>(tempo * 10)) / 10;
    if (_synth != NULL)
    {
        _synth->UpdateTempo([self now], _tempo);
    }
}

//  ---------------------------------------------------------------------------
//      start
//  ---------------------------------------------------------------------------
- (void)start
{
    if (_synth != NULL)
    {
        _synth->StartSequence([self now], _tempo);
    }
}

//  ---------------------------------------------------------------------------
//      stop
//  ---------------------------------------------------------------------------
- (void)stop
{
    if (_synth != NULL)
    {
        _synth->StopSequence([self now]);
    }
}

//  ---------------------------------------------------------------------------
//      now
//  ---------------------------------------------------------------------------
- (uint64_t)now
{
    return mach_absolute_time();
}

#pragma mark private methods

@end
