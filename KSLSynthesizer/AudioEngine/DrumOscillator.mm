//
//  DrumOscillator.mm
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#include "DrumOscillator.h"

//  ---------------------------------------------------------------------------
//      DrumOscillator::DrumOscillator
//  ---------------------------------------------------------------------------
DrumOscillator::DrumOscillator(float samplingRate) :
tgSamplingRate_(samplingRate),
pcmSamplingRate_(tgSamplingRate_),
transpose_(0),
tune_(0),
panCoef_(0),
isValid_(false),
numberOfFrames_(0),
currentAddress_(0),
pcmData_(),
isRunning_(false),
trigger_(false)
{
    this->SetPanPosition(64);
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::~DrumOscillator
//  ---------------------------------------------------------------------------
DrumOscillator::~DrumOscillator(void)
{
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::SetPanPosition
//  ---------------------------------------------------------------------------
void
DrumOscillator::SetPanPosition(const int pan)
{
#define CLIP(x, min, max)   (x < min ? min : (x > max ? max : x))
    const int32_t   panOfs = CLIP(pan, 0, 127) - 64;
    const int32_t   coef = (0x400000 + 66577 * panOfs) >> 8;
    panCoef_ = CLIP(coef, 0, 0x7FFF);
#undef CLIP
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::SetAmpCoefficient
//  ---------------------------------------------------------------------------
void
DrumOscillator::SetAmpCoefficient(const int32_t ampCoef)
{
#define CLIP(x, min, max)   (x < min ? min : (x > max ? max : x))
    ampCoef_ = CLIP(ampCoef, 0, 0xFFFF);
#undef CLIP
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::GetAmpCoefficient
//  ---------------------------------------------------------------------------
int32_t
DrumOscillator::GetAmpCoefficient(void)
{
    return ampCoef_;
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::CalculatePitch
//  ---------------------------------------------------------------------------
void
DrumOscillator::CalculatePitch(void)
{
    //  20.12
    const float pitch = static_cast<float>(transpose_) + static_cast<float>(tune_) / 100.0f;
    pitchOffset_ = static_cast<uint32_t>(::pow(2.0, pitch / 12.0f) * 
                                         ::pow(2.0, (::log(pcmSamplingRate_) - ::log(tgSamplingRate_)) / log(2.0)) *
                                         0x1000);
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::SetPcmSamplingRate
//  ---------------------------------------------------------------------------
void
DrumOscillator::SetPcmSamplingRate(float fs)
{
    pcmSamplingRate_ = fs;
    this->CalculatePitch();
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::TriggerOn
//  ---------------------------------------------------------------------------
void
DrumOscillator::TriggerOn(void)
{
    trigger_ = true;
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::GetOscOut
//  ---------------------------------------------------------------------------
inline int32_t
DrumOscillator::GetOscOut(void)
{
#define CLIP(x, min, max)   (x < min ? min : (x > max ? max : x))
    int32_t result = 0;
    if (!isValid_ || !isRunning_) {
        return result;
    }

    const uint32_t  addr = currentAddress_ >> 12;
    if (addr < numberOfFrames_) {
        const uint32_t  nextAddr = addr + 1;
        const int32_t   data = pcmData_[addr];
        const int32_t   nextData = (nextAddr < numberOfFrames_) ? pcmData_[nextAddr] : 0;
        const int32_t   interpolated = data + (((nextData - data) * static_cast<int32_t>(currentAddress_ & 0x0FFF)) >> 12);
        result = CLIP(interpolated, -0x7FFF, 0x7FFF);
        currentAddress_ += pitchOffset_;
    } else {
        isRunning_ = false;
    }

    return result;
#undef CLIP
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::ProcessAmp
//  ---------------------------------------------------------------------------
inline int32_t
DrumOscillator::ProcessAmp(int32_t oscOut)
{
#define CLIP(x, min, max)   (x < min ? min : (x > max ? max : x))
    const int32_t   amp = (oscOut * ampCoef_) >> 15;
    return CLIP(amp, -0x7FFF, 0x7FFF);
#undef CLIP
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::ProcessPan
//  ---------------------------------------------------------------------------
inline void
DrumOscillator::ProcessPan(int32_t ampOut, int32_t& left, int32_t& right)
{
    left = ((ampOut * (0x7FFF - panCoef_)) >> 15);
    right = (ampOut * panCoef_) >> 15;
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::Process
//  ---------------------------------------------------------------------------
void
DrumOscillator::Process(int16_t** output, int length)
{
#define CLIP(x, min, max)   (x < min ? min : (x > max ? max : x))
    if (trigger_)
    {
        isRunning_ = true;
        currentAddress_ = 0;
        trigger_ = false;
    }
    if (isRunning_)
    {
        int16_t*    left = output[0];
        int16_t*    right = output[1];
        for (int frame = 0; frame < length; ++frame)
        {
            int32_t leftOut, rightOut;
            this->ProcessPan(this->ProcessAmp(this->GetOscOut()), leftOut, rightOut);
            leftOut += *left;
            rightOut += *right;
            *(left++) = CLIP(leftOut, -0x7FFF, 0x7FFF);
            *(right++) = CLIP(rightOut, -0x7FFF, 0x7FFF);
            if (!isRunning_)
            {
                break;
            }
        }
    }
#undef CLIP
}

#pragma mark -
//  ---------------------------------------------------------------------------
//      DrumOscillator::LoadAudioFileInResourceFolder
//  ---------------------------------------------------------------------------
void
DrumOscillator::LoadAudioFileInResourceFolder(CFStringRef path)
{
    NSString*   resourcePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:(NSString*)CFBridgingRelease(path)];
    this->LoadAudioFile((CFStringRef)CFBridgingRetain(resourcePath));
}

//  ---------------------------------------------------------------------------
//      DrumOscillator::LoadAudioFile
//  ---------------------------------------------------------------------------
void
DrumOscillator::LoadAudioFile(CFStringRef path)
{
    bool    loaded = false;
    NSURL*  url = [[NSURL alloc] initFileURLWithPath:(NSString*)CFBridgingRelease(path)
                                         isDirectory:NO];
    ExtAudioFileRef fileRef = NULL;
    OSStatus    err = ::ExtAudioFileOpenURL((__bridge CFURLRef)(url), &fileRef);
    if (err == noErr)
    {
        AudioStreamBasicDescription fileFormat;
        UInt32  size = sizeof(fileFormat);
        err = ::ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileDataFormat, &size, &fileFormat);
        if (err == noErr)
        {
            //bool    isNonInterleave = ((fileFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0);
            if ((fileFormat.mFormatID == kAudioFormatLinearPCM) && 
                (fileFormat.mBitsPerChannel == 16) && 
                (fileFormat.mChannelsPerFrame == 1) && 
                ((fileFormat.mFormatFlags & kAudioFormatFlagIsSignedInteger) != 0) && 
                ((fileFormat.mFormatFlags & kAudioFormatFlagIsPacked) != 0))
            {
                pcmData_.clear();
                numberOfFrames_ = 0;
                this->SetPcmSamplingRate((float)fileFormat.mSampleRate);

                const UInt32    tmpFrames = 1024;
                std::vector<uint8_t>   tmpBuf(tmpFrames * fileFormat.mBytesPerFrame);
                AudioBufferList bufList;
                bufList.mNumberBuffers = 1;
                bufList.mBuffers[0].mNumberChannels = fileFormat.mChannelsPerFrame;
                bufList.mBuffers[0].mDataByteSize   = static_cast<const UInt32>(tmpBuf.size());
                bufList.mBuffers[0].mData           = &tmpBuf[0];

                while (true)
                {
                    UInt32 frames = tmpFrames;
                    bufList.mBuffers[0].mDataByteSize = static_cast<const UInt32>(tmpBuf.size());
                    err = ExtAudioFileRead(fileRef, &frames, &bufList);
                    if (err != noErr)
                    {
                        break;
                    }
                    if (frames == 0)
                    {
                        break;
                    }
                    else
                    {
                        int16_t*    src = static_cast<int16_t*>(bufList.mBuffers[0].mData);
                        pcmData_.reserve(pcmData_.size() + frames);
                        for (UInt32 i = 0; i < frames; ++i)
                        {
                            pcmData_.push_back(*(src++));
                        }
                        numberOfFrames_ += frames;
                    }
                }

                const bool  isBigEndian = ((fileFormat.mFormatFlags & kAudioFormatFlagIsBigEndian) != 0);
#if TARGET_RT_BIG_ENDIAN
                const bool  flipPcm = !isBigEndian;
#else
                const bool  flipPcm = isBigEndian;
#endif
                if (flipPcm)
                {
                    for (size_t index = 0; index < numberOfFrames_; ++index)
                    {
                        pcmData_.at(index) = ::CFSwapInt16(pcmData_.at(index));
                    }
                }
                
                loaded = true;
            }
        }
    }
    if (fileRef != NULL)
    {
        ::ExtAudioFileDispose(fileRef);
        fileRef = NULL;
    }

    isValid_ = loaded;
    if (!loaded)
    {
        pcmData_.clear();
        numberOfFrames_ = 0;
    }
}
