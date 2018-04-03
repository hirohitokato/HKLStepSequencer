//
//  Sequencer.h
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#pragma once

class SequencerListener
{
public:
    virtual ~SequencerListener(void)    {}
    virtual void    NoteOnViaSequencer(int frame, const std::vector<int> &parts, int step) = 0;
};

class Sequencer
{
public:
    Sequencer(float sampleRate);
    ~Sequencer(void);

    void    AddListener(SequencerListener* listener);
    void    RemoveListener(SequencerListener* listener);

    void    Start(const uint64_t hostTime, const float tempo);
    void    Stop(const uint64_t hostTime);

    void    UpdateTempo(const uint64_t hostTime, const float tempo);
    void    UpdateNumSteps(const uint64_t hostTime, const int numberOfSteps);
    void    UpdateTrack(const int trackNo, const std::vector<bool> &sequence);

    int     Process(class AudioIO* io, int offset, int length);

private:
    Sequencer(const Sequencer& other);                      //  not implemented
    const Sequencer& operator= (const Sequencer& other);    //  not implemented

    void    SetupTracks(void);

    typedef struct {
        uint64_t    hostTime;
        int         command;
        float       floatValue;
    } SeqCommandEvent;
    static inline bool  SortEventFunctor(const Sequencer::SeqCommandEvent& left, const Sequencer::SeqCommandEvent& right)
    {
        return (left.hostTime == right.hostTime) ? (left.command < right.command) : (left.hostTime < right.hostTime);
    }

    int     ProcessCommands(class AudioIO* io, int offset, int length);
    void    ProcessCommand(SeqCommandEvent& event);
    void    ProcessTrigger(int offset, const std::vector<int> &trackIndexes);
    void    ProcessTrigger(int offset);
    void    ProcessSequence(int offset, int length);
    void    AddCommand(const uint64_t hostTime, const int cmd, const float param0);

    const float samplingRate_;
    int     numberOfTracks_;
    int     numberOfSteps_;
    int     stepsPerBeats_;
    bool    isRunning_;
    int     currentStep_;
    float   stepFrameLength_;
    float   currentFrame_;
    bool    trigger_;
    std::vector< std::vector<bool> >   seq_;
    std::vector<SeqCommandEvent>   commands_;
    std::vector<SequencerListener*>  listeners_;
    std::mutex     commandsMutex_;
};
