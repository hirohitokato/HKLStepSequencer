//
//  Synthesizer.cpp
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#include <algorithm>
#include "Synthesizer.h"
#include "DrumOscillator.h"

//  ---------------------------------------------------------------------------
//      Synthesizer::Synthesizer
//  ---------------------------------------------------------------------------
Synthesizer::Synthesizer(float samplingRate) :
    samplingRate_(samplingRate),
    seq_(nullptr),
    seqEvents_(),
    oscillators_()
{
    seqEvents_.reserve(100);
}

//  ---------------------------------------------------------------------------
//      Synthesizer::~Synthesizer
//  ---------------------------------------------------------------------------
Synthesizer::~Synthesizer(void)
{
    CleanupOscillators();

    delete seq_;
    seq_ = NULL;
}

#pragma mark -
//
//  seq event type
//
enum
{
    kSeqEventParamType_Trigger = 0,
};

//  ---------------------------------------------------------------------------
//      Synthesizer::NoteOnViaSequencer
//  ---------------------------------------------------------------------------
void
Synthesizer::NoteOnViaSequencer(int frame, const std::vector<int> &parts, int step)
{
    for (const auto partNo : parts)
    {
        const SequencerEvent    param = { frame, kSeqEventParamType_Trigger, partNo, step };
        seqEvents_.push_back(param);
    }
}

//  ---------------------------------------------------------------------------
//      Synthesizer::DecodeSeqEvent
//  ---------------------------------------------------------------------------
inline void
Synthesizer::DecodeSeqEvent(const SequencerEvent* event)
{
    switch (event->paramType)
    {
        case kSeqEventParamType_Trigger:
            {
                const int   oscNo = event->value0;
                if ((oscNo >= 0) && (oscNo < static_cast<int>(oscillators_.size())))
                {
                    oscillators_[oscNo]->TriggerOn();
                }
            }
            break;
        default:
            break;
    }
}

//  ---------------------------------------------------------------------------
//      Synthesizer::RenderAudio
//  ---------------------------------------------------------------------------
inline void
Synthesizer::RenderAudio(AudioIO* /*io*/, int16_t** buffer, int length)
{
    for (auto oscillator: oscillators_) {
        oscillator->Process(buffer, length);
    }
}

//  ---------------------------------------------------------------------------
//      Synthesizer::ProcessReplacing
//  ---------------------------------------------------------------------------
void
Synthesizer::ProcessReplacing(AudioIO* io, int16_t** buffer, const uint32_t length)
{
    //  clear buffer
    ::memset(buffer[0], 0, length * sizeof(int16_t));
    ::memset(buffer[1], 0, length * sizeof(int16_t));

    int rest = static_cast<int>(length);
    int offset = 0;
    while (rest > 0)
    {            
        const int    frames = rest;
        const size_t numOfEvents = seqEvents_.size();
        const int    processed = (seq_ != NULL) ? seq_->Process(io, offset, frames) : frames;
        if (seqEvents_.size() > numOfEvents)
        {
            std::sort(seqEvents_.begin(), seqEvents_.end(), Synthesizer::SortEventFunctor);
        }
        if (processed > 0)
        {
            auto procLen = processed;
            auto curPos = offset;
            auto ite = seqEvents_.begin();
            while (procLen > 0)
            {
                int renderLen = procLen;
                bool    decode = false;
                const bool  iteIsValid = (ite != seqEvents_.end());
                if (iteIsValid)
                {
                    const int   pos = ite->frame - curPos;
                    if (pos < procLen)
                    {
                        renderLen = pos;
                        decode = true;
                    }
                }
                if (renderLen > 0)
                {
                    int16_t*    output[] = { buffer[0] + curPos , buffer[1] + curPos };
                    this->RenderAudio(io, output, renderLen);
                }
                if (iteIsValid)
                {
                    if (decode)
                    {
                        this->DecodeSeqEvent(&(*ite));
                    }
                    ++ite;
                }
                curPos += renderLen;
                procLen -= renderLen;
            }
            seqEvents_.clear();
        }

        offset += processed;
        rest -= processed;
    }
}

#pragma mark -
//  ---------------------------------------------------------------------------
//      Synthesizer::SetSequencer
//  ---------------------------------------------------------------------------
void
Synthesizer::SetSequencer(Sequencer *seq)
{
    seq_ = seq;
    seq_->AddListener(this);
}

//  ---------------------------------------------------------------------------
//      Synthesizer::StartSequence
//  ---------------------------------------------------------------------------
void
Synthesizer::StartSequence(uint64_t hostTime, float tempo)
{
    if (seq_ != NULL)
    {
        seq_->Start(hostTime, tempo);
    }
}

//  ---------------------------------------------------------------------------
//      Synthesizer::StopSequence
//  ---------------------------------------------------------------------------
void
Synthesizer::StopSequence(uint64_t hostTime)
{
    if (seq_ != NULL)
    {
        seq_->Stop(hostTime);
    }
}

//  ---------------------------------------------------------------------------
//      Synthesizer::CleanupOscillators
//  ---------------------------------------------------------------------------
void
Synthesizer::CleanupOscillators()
{
    for (size_t oscNo = 0; oscNo < oscillators_.size(); ++oscNo)
    {
        delete oscillators_[oscNo];
    }
    oscillators_.clear();
}

//  ---------------------------------------------------------------------------
//      Synthesizer::SetSoundSet
//  ---------------------------------------------------------------------------
void
Synthesizer::SetSoundSet(const std::vector<std::string> &soundfiles)
{
    CleanupOscillators();

    for (const auto &soundfile: soundfiles) {
        DrumOscillator* osc = new DrumOscillator(samplingRate_);
        osc->LoadAudioFileInResourceFolder(soundfile);
        osc->SetPanPosition(64);
        oscillators_.push_back(osc);
    }
}

//  ---------------------------------------------------------------------------
//      Synthesizer::SetAmpCoefficient
//  ---------------------------------------------------------------------------
void
Synthesizer::SetAmpCoefficient(const int partNo, const int32_t ampCoef)
{
    if (static_cast<size_t>(partNo) < oscillators_.size()) {
        oscillators_[partNo]->SetAmpCoefficient(ampCoef);
    }
}

//  ---------------------------------------------------------------------------
//      Synthesizer::SetPanPosition
//  ---------------------------------------------------------------------------
void
Synthesizer::SetPanPosition(const int partNo, const int pan)
{
    if (static_cast<size_t>(partNo) < oscillators_.size()) {
        oscillators_[partNo]->SetPanPosition(pan);
    }
}
