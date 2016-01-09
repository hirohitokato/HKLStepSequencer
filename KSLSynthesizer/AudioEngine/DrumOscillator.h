//
//  DrumOscillator.h
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#pragma once

#include <vector>

class DrumOscillator
{
public:
    DrumOscillator(float samplingRate);
    ~DrumOscillator(void);

    void    SetPanpot(int pan);

    void    Process(int16_t** output, int length);
    void    TriggerOn(void);

    void    LoadAudioFileInResourceFolder(CFStringRef path);

private:
    void    LoadAudioFile(CFStringRef path);
    void    SetPcmSamplingRate(float fs);
    void    CalculatePitch(void);
    int32_t GetOscOut(void);
    int32_t ProcessAmp(int32_t oscOut);
    void    ProcessPan(int32_t ampOut, int32_t& left, int32_t& right);

    const float     tgSamplingRate_;
    const int32_t   ampCoef_;
    float       pcmSamplingRate_;
    int32_t     transpose_;
    int32_t     tune_;
    uint32_t    pitchOffset_;
    int32_t     panCoef_;
    bool        isValid_;
    uint32_t    numberOfFrames_;
    uint32_t    currentAddress_;
    std::vector<int16_t>    pcmData_;
    bool        isRunning_;
    bool        trigger_;
};
