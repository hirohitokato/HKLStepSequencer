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

    void    NoteOnViaSequencer(int /*frame*/, const std::vector<int> &parts, int step) {

        uint64_t now = mach_absolute_time();
        if (respondableToSelector_ == -1) {
            respondableToSelector_ = [receiver_.delegate respondsToSelector:@selector(audioEngine:didTriggeredTracks:step:atTime:)];
        }
        if (respondableToSelector_) {
            NSMutableArray<NSNumber *>* tracks = [@[] mutableCopy];
            for (auto partNo : parts) {
                [tracks addObject:[NSNumber numberWithInt:partNo]];
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [receiver_.delegate audioEngine:receiver_
                             didTriggeredTracks:tracks
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
    if (_sequencer != nullptr)
    {
        _sequencer->UpdateTempo([self now], static_cast<float>(_tempo));
    }
}

//  ---------------------------------------------------------------------------
//      setNumSteps
//  ---------------------------------------------------------------------------
- (void)setNumSteps:(NSInteger)numSteps
{
    _numSteps = numSteps;
    if (_sequencer != nullptr) {
        _sequencer->UpdateNumSteps([self now], static_cast<int>(_numSteps));
    }
}

//  ---------------------------------------------------------------------------
//      setSounds
//  ---------------------------------------------------------------------------
- (void)setSounds:(NSArray<NSString *> *)sounds
{
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
//      setStepSequence:ofTrack:
//  ---------------------------------------------------------------------------
- (void)setStepSequence:(NSArray<NSNumber *> *)sequence ofTrack:(NSInteger)trackNo
{
    if (_synth != nullptr) {
        if (sequence.count == (NSUInteger)_numSteps) {
            std::vector<bool> seq;
            for (NSNumber *stepObj in sequence) {
                seq.push_back(stepObj.boolValue);
            }
            _sequencer->UpdateTrack(static_cast<int>(trackNo), seq);
        }
    }
}

//  ---------------------------------------------------------------------------
//      clearSequence:
//  ---------------------------------------------------------------------------
- (void)clearSequence:(NSInteger)trackNo
{
    if (_synth != nullptr) {
        std::vector<bool> seq;
        for (int i=0; i<_numSteps; ++i) {
            seq.push_back(false);
        }
        _sequencer->UpdateTrack(static_cast<int>(trackNo), seq);
    }
}

//  ---------------------------------------------------------------------------
//      setAmpGain:ofTrack:
//  ---------------------------------------------------------------------------
- (void)setAmpGain:(double)ampGain ofTrack:(NSInteger)trackNo
{
    if (_synth != nullptr) {
        if (ampGain >= 0.0 && ampGain <= 2.0) {
            int32_t gain = ampGain * 0x7FFF;
            _synth->SetAmpCoefficient(static_cast<int>(trackNo), gain);
        }
    }
}

//  ---------------------------------------------------------------------------
//      setPanPosition:ofTrack:
//  ---------------------------------------------------------------------------
- (void)setPanPosition:(double)position ofTrack:(NSInteger)trackNo
{
    if (_synth != nullptr) {
        if (position >= -1.0 && position <= 1.0) {
            int32_t pos = (position + 1.0) * 64;
            _synth->SetPanPosition(static_cast<int>(trackNo), pos);
        }
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
