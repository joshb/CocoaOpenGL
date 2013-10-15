/*
 * Copyright (C) 2013 Josh A. Beam
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "Matrix4.h"

@interface Matrix4()
{
    float _matrix[16];
}

@end

@implementation Matrix4

- (id)init
{
    if((self = [super init])) {
        const float identityData[] = {
            1.0f, 0.0f, 0.0f, 0.0f,
            0.0f, 1.0f, 0.0f, 0.0f,
            0.0f, 0.0f, 1.0f, 0.0f,
            0.0f, 0.0f, 0.0f, 1.0f
        };
        
        memcpy(_matrix, identityData, sizeof(_matrix));
    }
    
    return self;
}

- (const float *)data
{
    return _matrix;
}

- (float)getValueForIndex:(int)index
{
    if(index < 0 || index > 15) {
        NSLog(@"Invalid matrix element index %d; must be between 0 and 15", index);
        return 0.0f;
    }
    
    return _matrix[index];
}

- (void)setValue:(float)value forIndex:(int)index
{
    if(index < 0 || index > 15) {
        NSLog(@"Invalid matrix element index %d; must be between 0 and 15", index);
    } else {
        _matrix[index] = value;
    }
}

+ (Matrix4 *)translationMatrixWithX:(float)x y:(float)y z:(float)z
{
    Matrix4 *matrix = [[Matrix4 alloc] init];
    [matrix setValue:x forIndex:12];
    [matrix setValue:y forIndex:13];
    [matrix setValue:z forIndex:14];
    return [matrix autorelease];
}

@end
