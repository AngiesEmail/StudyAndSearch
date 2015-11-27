//
//  KXRef.h
//  StudyAndSearch
//
//  Created by playcrab on 15/11/27.
//  Copyright (c) 2015年 Angie. All rights reserved.
//

#ifndef __StudyAndSearch__KXRef__
#define __StudyAndSearch__KXRef__

#include <stdio.h>
#include <assert.h>
class Ref;
class Clonable
{
public:
    //返回Ref的拷贝
    virtual Clonable* clone() const = 0;
    virtual ~Clonable(){};
    //现在暂时这个好像是不需要的
    Ref* copy()const
    {
        assert(false);
        return nullptr;
    }
};
class Ref {
public:
    void retain();
    void release();
    Ref* autorelease();
    unsigned int getReferenceCount() const;
protected:
    Ref();
public:
    virtual ~Ref();
protected:
    unsigned int _referenceCount;
    friend class AutoreleasePool;
public:
    //内存泄露
    static void printLeaks();
};
#endif /* defined(__StudyAndSearch__KXRef__) */
