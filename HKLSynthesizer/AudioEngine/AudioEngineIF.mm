//
//  AudioEngineIF.mm
//
//  Created by Hirohito Kato on 2016/01/08.
//  Copyright © 2016 Hirohito Kato. All rights reserved.
//

#include <string>
#include <mutex>

#import <mach/mach_time.h>

#import "AudioIO.h"
#import "Sequencer.h"
#import "DrumOscillator.h"
#import "Synthesizer.h"

#import "AudioEngineIF.h"

class SequencerConnector : public SequencerListener {
    AudioEngineIF *receiver_;
    AudioIO *io_;
    BOOL respondableToSelector_;
public:
    SequencerConnector(AudioEngineIF *receiver, AudioIO *io) :
    receiver_(receiver), io_(io), respondableToSelector_(NO) {}

    void    NoteOnViaSequencer(int offset, const std::vector<int> &parts, int step) {

        uint64_t triggeredTime = io_->GetHostTime() + offset;
        if (respondableToSelector_ == NO) {
            respondableToSelector_ = [receiver_.delegate respondsToSelector:@selector(audioEngine:willTriggerTracks:step:atTime:)];
        }
        if (respondableToSelector_) {
            NSMutableArray<NSNumber *>* tracks = [@[] mutableCopy];
            for (auto partNo : parts) {
                [tracks addObject:[NSNumber numberWithInt:partNo]];
            }

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [receiver_.delegate audioEngine:receiver_
                              willTriggerTracks:tracks
                                           step:step
                                         atTime:triggeredTime];
            });
        }
    }
};

static inline uint64_t now() {
    return mach_absolute_time();
}

@interface AudioEngineIF ()
@property (nonatomic) Synthesizer*        synth;
@property (nonatomic) AudioIO*            audioIo;
@property (nonatomic) SequencerConnector* connector;
@property (nonatomic) Sequencer*          sequencer;

@property (nonatomic, readwrite) float    frequency;
@property (nonatomic) NSInteger           stepsPerBeat;
@end

@implementation AudioEngineIF

- (instancetype)init
{
    NSAssert(false, @"AudioEngineIF must be initialized with public API.");
    return nil;
}

- (instancetype)initWithNumOfTracks:(int)numTracks
                         numOfSteps:(int)numSteps
                       stepsPerBeat:(int)stepsPerBeat;
{
    self = [super init];
    if (self != nil)
    {
        _tempo = 120.0f;
        _frequency = 44100.0f;
        _numSteps = numSteps;
        _stepsPerBeat = stepsPerBeat;

        _audioIo = new AudioIO(_frequency);
        _synth = new Synthesizer(_frequency);
        _sequencer = new Sequencer(_frequency,
                                   numTracks/*tracks*/,
                                   (int)_numSteps/*steps*/,
                                   (int)_stepsPerBeat/*stepsPerBeat*/);

        _audioIo->SetListener(_synth);
        _synth->SetSequencer(_sequencer);

        _connector = new SequencerConnector(self, _audioIo);
        _sequencer->AddListener(_connector);

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
        _sequencer->UpdateTempo(now(), static_cast<float>(_tempo));
    }
}

//  ---------------------------------------------------------------------------
//      numTracks
//  ---------------------------------------------------------------------------
- (NSInteger)numTracks
{
    if (_sequencer != nullptr) {
        return _sequencer->GetNumTracks();
    }
    return -1;
}
- (void)setNumTracks:(NSInteger)numTracks
{
    if (_synth != nullptr) {
        _synth->StopSequence(now());

        if (_sequencer != nullptr) {
            delete _sequencer;
        }
        _sequencer = new Sequencer(_frequency,
                                   (int)numTracks/*tracks*/,
                                   (int)_numSteps/*steps*/,
                                   (int)_stepsPerBeat/*stepsPerBeat*/);
        _synth->SetSequencer(_sequencer);
        _sequencer->AddListener(_connector);

    }
}

//  ---------------------------------------------------------------------------
//      setNumSteps
//  ---------------------------------------------------------------------------
- (void)setNumSteps:(NSInteger)numSteps
{
    _numSteps = numSteps;
    if (_sequencer != nullptr) {
        _sequencer->UpdateNumSteps(now(), static_cast<int>(_numSteps));
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
        _synth->StartSequence(now(), static_cast<float>(_tempo));
    }
}

//  ---------------------------------------------------------------------------
//      stop
//  ---------------------------------------------------------------------------
- (void)stop
{
    if (_synth != nullptr)
    {
        _synth->StopSequence(now());
    }
}

@end
