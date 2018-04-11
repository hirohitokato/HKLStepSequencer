//
//  AudioIO.h
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#pragma once
#include <AudioToolbox/AudioToolbox.h>
#include <vector>

class AudioIOListener
{
public:
    virtual ~AudioIOListener(void)    {}
    virtual void ProcessReplacing(class AudioIO* io, int16_t** buffer, const uint32_t length) = 0;
};


class AudioIO
{
public:
    AudioIO(float samplingRate);
    ~AudioIO(void);

    bool    Open(void);
    bool    Close(void);
    bool    Start(void);
    bool    Stop(void);

    bool    IsRunning(void) const;

    uint64_t    GetHostTime(void) const     { return hostTime_; }
    uint64_t    GetLatency(void) const      { return latency_; }

    void    SetListener(AudioIOListener* listener);
    
    Float32 GetCPULoad(void) const;
    Float32 GetMaxCPULoad(void) const;

    static void InterruptionCallback(void* inClientData, UInt32 inInterruptionState);
    static void AudioRouteChangeCallback(void* inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void* inData);

protected:
    void    Render(AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber,
                   UInt32 inNumberFrames, AudioBufferList* ioData);
    static OSStatus RenderCallback(void *inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp,
                                   UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData);

    void        InitializeAudioSession(void);
    void        Interrupt(UInt32 state);
    void        AudioRouteChange(AudioSessionPropertyID inID, UInt32 inDataSize, const void* inData);
    void        SetIOBufferSize(void);

private:
    AudioIO(const AudioIO& other);                      //  not implemented
    const AudioIO& operator= (const AudioIO& other);    //  not implemented

    AudioIOListener*    listener_;
    const uint32_t  bufferLength_;
    const uint32_t  numberOfOutputBus_;
    const Float32   sampleRate_;
    uint32_t        ioBufferSize_;
    AudioUnit       remoteIOUnit_;
    AUGraph         auGraph_;
    bool            isRunning_;
    std::vector<int16_t>    dataBuffer_;
    std::vector<int16_t*>   outputBuffer_;
    uint64_t    hostTime_;
    uint64_t    latency_;

    void *receiver;
};
