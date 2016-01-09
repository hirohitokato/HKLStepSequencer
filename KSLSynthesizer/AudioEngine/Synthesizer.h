//
//  Synthesizer.h
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#pragma once

#include <vector>
#include "AudioIO.h"
#include "Sequencer.h"

class DrumOscillator;

class Synthesizer : public AudioIOListener, SequencerListener
{
public:
    Synthesizer(float samplingRate);
    ~Synthesizer(void);

    //  AudioIOListener
    void    ProcessReplacing(AudioIO* io, int16_t** buffer, int length);

    //  SequencerListener
    void    NoteOnViaSequencer(int frame, int partNo, int step);

    void    StartSequence(uint64_t hostTime, float tempo);
    void    StopSequence(uint64_t hostTime);
    void    UpdateTempo(uint64_t hostTime, float tempo);

    Sequencer *GetSequencer() { return seq_; }

private:
    Synthesizer(const Synthesizer& other) = delete;
    const Synthesizer& operator= (const Synthesizer& other) = delete;

    typedef struct {
        int32_t frame;
        int     paramType;
        int     value0;
        int     value1;
    } SequencerEvent;
    static inline bool SortEventFunctor(const Synthesizer::SequencerEvent& left,
                                        const Synthesizer::SequencerEvent& right)
    {
        return (left.frame == right.frame) ? (left.paramType < right.paramType) : (left.frame < right.frame);
    }

    void    RenderAudio(AudioIO* io, int16_t** buffer, int length);
    void    DecodeSeqEvent(const SequencerEvent* event);

    const float samplingRate_;
    Sequencer*  seq_;
    std::vector<SequencerEvent> seqEvents_;
    std::vector<DrumOscillator*> oscillators_;
};
