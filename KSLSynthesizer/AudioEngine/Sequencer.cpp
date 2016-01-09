//
//  Sequencer.cpp
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#include <mach/mach_time.h>
#include <algorithm>
#include "Sequencer.h"
#include "AudioIO.h"
#include "ScopedLock.h"

//  ---------------------------------------------------------------------------
//      Sequencer::Sequencer
//  ---------------------------------------------------------------------------
Sequencer::Sequencer(float samplingRate) :
samplingRate_(samplingRate),
numberOfSteps_(12), // 全体で12ステップのシーケンサー
stepsPerBeats_(12), // 1ビートで12拍
isRunning_(false),
currentStep_(0),
stepFrameLength_(0),
currentFrame_(0),
trigger_(false),
seq_(),
commands_(),
listeners_(),
commandsMutex_()
{
    // 各ステップの再生有無をstd::vector<bool>で記憶するトラックを4本作成
    const int   kNumberOfTrack  = 4;
    for (int trackNo = 0; trackNo < kNumberOfTrack; ++trackNo)
    {
        std::vector<bool>   partSeq(numberOfSteps_, false);
        seq_.push_back(partSeq);
    }
    // 各トラックの再生タイミングをデフォルト値で作成
    this->SetDefault();
}

//  ---------------------------------------------------------------------------
//      Sequencer::~Sequencer
//  ---------------------------------------------------------------------------
Sequencer::~Sequencer(void)
{
}

//  ---------------------------------------------------------------------------
//      Sequencer::Set
//  ---------------------------------------------------------------------------
void
Sequencer::Set(int trackNo, int stepNo, bool sw)
{
    if ((trackNo >= 0) && (trackNo < static_cast<int>(seq_.size())))
    {
        std::vector<bool>&   track = seq_[trackNo];
        if ((stepNo >= 0) && (stepNo < static_cast<int>(track.size())))
        {
            track[stepNo] = sw;
        }
    }
}

//  ---------------------------------------------------------------------------
//      Sequencer::SetDefault
//  ---------------------------------------------------------------------------
void
Sequencer::SetDefault(void)
{
    for (int step = 0; step < numberOfSteps_; ++step)
    {
        this->Set(0, step, ((step % 3) == 0));  // トラック1 - kick.wav
        this->Set(1, step, ((step % 4) == 4));  // トラック2 - snare.wav
        this->Set(2, step, ((step % 2) == 0));  // トラック3 - zap.wav
        this->Set(3, step, true);               // トラック4 - noiz.wav
    }
}

enum
{
    kSeqCommand_Start = 0,
    kSeqCommand_Stop,
    kSeqCommand_UpdateTempo,
};

//  ---------------------------------------------------------------------------
//      Sequencer::ProcessCommand
//  ---------------------------------------------------------------------------
inline void
Sequencer::ProcessCommand(SeqCommandEvent& event)
{
    switch (event.command)
    {
        case kSeqCommand_Start:
            if (!isRunning_)
            {
                const float tempo = event.floatValue;
                currentStep_ = 0;
                currentFrame_ = 0;
                stepFrameLength_ = samplingRate_ * 60.0f / tempo / 12;   //  length = 1/16
                trigger_ = true;
                isRunning_ = true;
            }
            break;
        case kSeqCommand_Stop:
            if (isRunning_)
            {
                isRunning_ = false;
            }
            break;
        case kSeqCommand_UpdateTempo:
            if (1)
            {
                const float tempo = event.floatValue;
                stepFrameLength_ = samplingRate_ * 60.0f / tempo / 12;   //  length = 1/16
            }
        default:
            break;
    }
}

//  ---------------------------------------------------------------------------
//      Sequencer::ProcessCommands
//  ---------------------------------------------------------------------------
inline int
Sequencer::ProcessCommands(AudioIO* io, int offset, int length)
{
    if (!commands_.empty())
    {
        const uint64_t  hostTime = (io != NULL) ? io->GetHostTime() : 0;
        const uint64_t  latency = (io != NULL) ? io->GetLatency() : 0;
        mach_timebase_info_data_t timeInfo;
        ::mach_timebase_info(&timeInfo);
        {
            ScopedLock<CriticalSection> lock(commandsMutex_);
            std::sort(commands_.begin(), commands_.end(), Sequencer::SortEventFunctor);
            for (std::vector<SeqCommandEvent>::iterator ite = commands_.begin(); ite != commands_.end();)
            {
                bool    doProcess = false;
                if (ite->hostTime == 0)    //  now
                {
                    doProcess = true;
                }
                else if (io != NULL)
                {
                    const int64_t   delta = ite->hostTime - hostTime;
                    const int64_t   deltaNanosec = delta * timeInfo.numer / timeInfo.denom + latency;
                    const int32_t   sampleOffset = static_cast<int32_t>(static_cast<double>(deltaNanosec) * samplingRate_ / 1000000000);
                    if (sampleOffset < offset + length)
                    {
                        const int   eventFrame = sampleOffset - offset;
                        if (eventFrame > 0)
                        {
                            return eventFrame;
                        }
                        doProcess = true;
                    }
                }
                if (doProcess)
                {
                    this->ProcessCommand(*ite);
                    ite = commands_.erase(ite);
                }
                else
                {
                    ++ite;
                }
            }
        }
    }
    return length;
}

//  ---------------------------------------------------------------------------
//      Sequencer::ProcessTrigger
//  ---------------------------------------------------------------------------
inline void
Sequencer::ProcessTrigger(int offset, int trackNo)
{
    for (auto obj : listeners_)
    {
        obj->NoteOnViaSequencer(offset, trackNo, currentStep_);
    }
}

//  ---------------------------------------------------------------------------
//      Sequencer::ProcessTrigger
//  ---------------------------------------------------------------------------
inline void
Sequencer::ProcessTrigger(int offset)
{
    if (trigger_ && (currentFrame_ >= 0))
    {
        if ((currentStep_ >= 0) && (currentStep_ < numberOfSteps_))
        {
            const int   numOfTrack = static_cast<const int>(seq_.size());
            for (int trackNo = 0; trackNo < numOfTrack; ++trackNo)
            {
                std::vector<bool>&   partSeq = seq_[trackNo];
                if (partSeq[currentStep_])
                {
                    this->ProcessTrigger(offset + currentFrame_, trackNo);
                }
            }
        }
        trigger_ = false;
    }
}

//  ---------------------------------------------------------------------------
//      Sequencer::ProcessSequence
//  ---------------------------------------------------------------------------
inline void
Sequencer::ProcessSequence(int offset, int length)
{
    int rest = length;
    int startFrame = offset;
    while (rest > 0)
    {
        const int   processedLen = std::min<int>(rest, std::max<int>(stepFrameLength_ - currentFrame_, 1));
        this->ProcessTrigger(startFrame);
        currentFrame_ += processedLen;
        rest -= processedLen;
        startFrame += processedLen;
        if (currentFrame_ >= stepFrameLength_)
        {
            currentFrame_ -= stepFrameLength_;
            ++currentStep_;
            if (currentStep_ > numberOfSteps_ - 1)
            {
                currentStep_ = 0;
            }
            trigger_ = true;
        }
    }
}

//  ---------------------------------------------------------------------------
//      Sequencer::Process
//  ---------------------------------------------------------------------------
int
Sequencer::Process(AudioIO* io, int offset, int length)
{
    const int   result = this->ProcessCommands(io, offset, length);
    if (isRunning_ && (result > 0))
    {
        this->ProcessSequence(offset, result);
    }
    return result;
}

#pragma mark -
//  ---------------------------------------------------------------------------
//      Sequencer::AddListener
//  ---------------------------------------------------------------------------
void
Sequencer::AddListener(SequencerListener* listener)
{
    listeners_.push_back(listener);
}

//  ---------------------------------------------------------------------------
//      Sequencer::RemoveListener
//  ---------------------------------------------------------------------------
void
Sequencer::RemoveListener(SequencerListener* listener)
{
    listeners_.erase(std::remove(std::begin(listeners_),
                                 std::end(listeners_),
                                 listener), std::end(listeners_));
}

#pragma mark -
//  ---------------------------------------------------------------------------
//      Sequencer::AddCommand
//  ---------------------------------------------------------------------------
void
Sequencer::AddCommand(uint64_t hostTime, int cmd, float param0)
{
    ScopedLock<CriticalSection> lock(commandsMutex_);
    const SeqCommandEvent   event = { hostTime, cmd, param0 };
    commands_.push_back(event);
}

//  ---------------------------------------------------------------------------
//      Sequencer::Start
//  ---------------------------------------------------------------------------
void
Sequencer::Start(uint64_t hostTime, float tempo)
{
    this->AddCommand(hostTime, kSeqCommand_Start, tempo);
}

//  ---------------------------------------------------------------------------
//      Sequencer::Stop
//  ---------------------------------------------------------------------------
void
Sequencer::Stop(uint64_t hostTime)
{
    this->AddCommand(hostTime, kSeqCommand_Stop, 0.0f/* ignore */);
}

//  ---------------------------------------------------------------------------
//      Sequencer::UpdateTempo
//  ---------------------------------------------------------------------------
void
Sequencer::UpdateTempo(uint64_t hostTime, float tempo)
{
    this->AddCommand(hostTime, kSeqCommand_UpdateTempo, tempo);
}
