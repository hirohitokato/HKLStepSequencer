//
//  Sequencer.cpp
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#include <vector>
#include <mutex>
#include <algorithm>

#include <mach/mach_time.h>

#include "Sequencer.h"
#include "AudioIO.h"

//  ---------------------------------------------------------------------------
//      Sequencer::Sequencer
//  ---------------------------------------------------------------------------
Sequencer::Sequencer(float samplingRate, int numberOfTracks, int numberOfSteps, int stepsPerBeat) :
samplingRate_(samplingRate),
numberOfTracks_(numberOfTracks),
numberOfSteps_(numberOfSteps),
stepsPerBeat_(stepsPerBeat),
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
    SetupTracks();
}

//  ---------------------------------------------------------------------------
//      Sequencer::~Sequencer
//  ---------------------------------------------------------------------------
Sequencer::~Sequencer(void)
{
}

//  ---------------------------------------------------------------------------
//      Sequencer::SetupTracks
//  ---------------------------------------------------------------------------
void
Sequencer::SetupTracks()
{
    seq_.clear();
    for (int trackNo = 0; trackNo < numberOfTracks_; ++trackNo)
    {
        std::vector<bool>   partSeq(numberOfSteps_, false);
        seq_.push_back(partSeq);
    }
}

enum
{
    kSeqCommand_Start = 0,
    kSeqCommand_Stop,
    kSeqCommand_UpdateTempo,
    kSeqCommand_UpdateNumSteps,
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
                stepFrameLength_ = samplingRate_ * 60.0f / tempo / stepsPerBeat_;
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
                stepFrameLength_ = samplingRate_ * 60.0f / tempo / stepsPerBeat_;
            }
            break;
        case kSeqCommand_UpdateNumSteps:
            if (1) {
                const int numberOfSteps = static_cast<int>(event.floatValue);
                if (numberOfSteps != numberOfSteps_) {
                    numberOfSteps_ = numberOfSteps;
                    SetupTracks();
                }
            }
            break;
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
            std::lock_guard<std::mutex> lock(commandsMutex_);
            std::sort(commands_.begin(), commands_.end(), Sequencer::SortEventFunctor);
            for (auto ite = commands_.begin(); ite != commands_.end();)
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
Sequencer::ProcessTrigger(int offset, const std::vector<int> &trackIndexes)
{
    for (auto listener : listeners_)
    {
        listener->NoteOnViaSequencer(offset, trackIndexes, currentStep_);
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
            // ここでONトラック(int)だけを集めてProcessTriggerに渡す
            std::vector<int> triggeredTracks;
            const int   numOfTrack = static_cast<const int>(seq_.size());
            for (int trackNo = 0; trackNo < numOfTrack; ++trackNo)
            {
                const auto&   partSeq = seq_[trackNo];
                if (partSeq[currentStep_])
                {
                    triggeredTracks.push_back(trackNo);
                }
            }
            this->ProcessTrigger(offset + currentFrame_, triggeredTracks);
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
Sequencer::AddCommand(const uint64_t hostTime, const int cmd, const float param0)
{
    std::lock_guard<std::mutex> lock(commandsMutex_);
    const SeqCommandEvent   event = { hostTime, cmd, param0 };
    commands_.push_back(event);
}

//  ---------------------------------------------------------------------------
//      Sequencer::Start
//  ---------------------------------------------------------------------------
void
Sequencer::Start(const uint64_t hostTime, const float tempo)
{
    this->AddCommand(hostTime, kSeqCommand_Start, tempo);
}

//  ---------------------------------------------------------------------------
//      Sequencer::Stop
//  ---------------------------------------------------------------------------
void
Sequencer::Stop(const uint64_t hostTime)
{
    this->AddCommand(hostTime, kSeqCommand_Stop, 0.0f/* ignore */);
}

//  ---------------------------------------------------------------------------
//      Sequencer::UpdateTempo
//  ---------------------------------------------------------------------------
void
Sequencer::UpdateTempo(const uint64_t hostTime, const float tempo)
{
    this->AddCommand(hostTime, kSeqCommand_UpdateTempo, tempo);
}

//  ---------------------------------------------------------------------------
//      Sequencer::UpdateNumSteps
//  ---------------------------------------------------------------------------
void
Sequencer::UpdateNumSteps(const uint64_t hostTime, const int numberOfSteps)
{
    this->AddCommand(hostTime, kSeqCommand_UpdateNumSteps, numberOfSteps);
}

//  ---------------------------------------------------------------------------
//      Sequencer::UpdateTrack
//  ---------------------------------------------------------------------------
void
Sequencer::UpdateTrack(const int trackNo, const std::vector<bool> &sequence)
{
    if ((trackNo >= 0) && (trackNo < static_cast<int>(seq_.size())))
    {
        seq_[trackNo] = sequence;
    }
}
