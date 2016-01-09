//
//  ScopedLock.h
//  WISTSample
//
//  Created by Nobuhisa Okamura on 11/05/19.
//  Copyright 2011 KORG INC. All rights reserved.
//

#pragma once

template <typename T>
class ScopedLock
{
public:
    ScopedLock(T& lock) : obj_(lock)    { obj_.Lock(); }
    ~ScopedLock(void)                   { obj_.Unlock(); }

private:
    const ScopedLock& operator= (const T&);     //  not implemented
    T& obj_;
};
