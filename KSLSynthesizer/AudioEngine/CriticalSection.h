//
//  CriticalSection.h
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#pragma once

#include <pthread.h>

class CriticalSection
{
public:
    CriticalSection(void) : mutex_()
    {
        pthread_mutexattr_t attr;
        ::pthread_mutexattr_init(&attr);
        ::pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        ::pthread_mutex_init(&mutex_, &attr);
    }
    ~CriticalSection(void)  { ::pthread_mutex_destroy(&mutex_); }

    void    Lock(void)      { ::pthread_mutex_lock(&mutex_); }
    bool    TryLock(void)   { return (::pthread_mutex_trylock(&mutex_) == 0); }
    void    Unlock(void)    { ::pthread_mutex_unlock(&mutex_); }

private:
    CriticalSection(const CriticalSection&) = delete;
    const CriticalSection& operator= (const CriticalSection&) = delete;

    pthread_mutex_t mutex_;
};
