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
#import "Sequencer.h"

class SequencerConnector : public SequencerListener {
    AudioEngineIF *receiver_;
    int respondableToSelector_;
public:
    SequencerConnector(AudioEngineIF *receiver) :
    receiver_(receiver), respondableToSelector_(-1) {}
    void NoteOnViaSequencer(int /*frame*/, int partNo, int step) {
        uint64_t now = mach_absolute_time();
        if (respondableToSelector_ == -1) {
            respondableToSelector_ = [receiver_.delegate respondsToSelector:@selector(audioEngine:didTriggeredTrack:step:atTime:)];
        }
        if (respondableToSelector_) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [receiver_.delegate audioEngine:receiver_
                              didTriggeredTrack:partNo
                                           step:step
                                         atTime:now];
            });
        }
    }
};

@interface AudioEngineIF ()
@property (nonatomic) Synthesizer*        synth;
@property (nonatomic) AudioIO*            audioIo;
@property (nonatomic) SequencerConnector* connector;
@property (nonatomic) Sequencer*          sequencer;
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
        _sequencer = new Sequencer(fs);
        _audioIo = new AudioIO(fs);
        _connector = new SequencerConnector(self);

        _synth->SetSequencer(_sequencer);
        _sequencer->AddListener(_connector);
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
    _audioIo = nullptr;
    delete _synth;
    _synth = nullptr;
    delete _sequencer;
    _sequencer = nullptr;
    delete _connector;
    _connector = nullptr;
}

#pragma mark -

//  ---------------------------------------------------------------------------
//      latency
//  ---------------------------------------------------------------------------
- (uint64_t)latency
{
    uint64_t    result = 0;
    if (_audioIo != nullptr)
    {
        result += _audioIo->GetLatency();  //  audio i/o latency
    }
    return result;  //  nanosec
}

#pragma mark public property & methods
//  ---------------------------------------------------------------------------
//      setTempo
//  ---------------------------------------------------------------------------
- (void)setTempo:(double)tempo
{
    _tempo = static_cast<float>(static_cast<int>(tempo * 10)) / 10;
    if (_synth != nullptr)
    {
        _synth->UpdateTempo([self now], static_cast<float>(_tempo));
    }
}

//  ---------------------------------------------------------------------------
//      setNumSteps
//  ---------------------------------------------------------------------------
- (void)setNumSteps:(NSInteger)numSteps
{
    _numSteps = numSteps;
    if (_synth != nullptr) {
        _sequencer->UpdateNumSteps([self now], static_cast<int>(_numSteps));
    }
}

//  ---------------------------------------------------------------------------
//      setSounds
//  ---------------------------------------------------------------------------
- (void)setSounds:(NSArray<NSString *> *)sounds {
    if (_synth != nullptr)
    {
        _sounds = [sounds copy];
        std::vector<std::string> soundsVector;
        for (NSString *sound in sounds) {
            std::string sound_cstr([sound cStringUsingEncoding:NSUTF8StringEncoding]);
            soundsVector.emplace_back(sound_cstr);
        }
        _synth->SetSoundSet(soundsVector);
    }
}

//  ---------------------------------------------------------------------------
//      start
//  ---------------------------------------------------------------------------
- (void)start
{
    if (_synth != nullptr)
    {
        _synth->StartSequence([self now], static_cast<float>(_tempo));
    }
}

//  ---------------------------------------------------------------------------
//      stop
//  ---------------------------------------------------------------------------
- (void)stop
{
    if (_synth != nullptr)
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
