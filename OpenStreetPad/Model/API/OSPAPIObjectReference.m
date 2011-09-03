//
//  OSPAPIObjectReference.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 29/08/2011.
//  Copyright (c) 2011 In The Beginning... All rights reserved.
//

#import "OSPAPIObjectReference.h"

@interface OSPAPIObjectReference ()

@property (readwrite, assign) OSPMemberType type;

@end

@implementation OSPAPIObjectReference

@synthesize type;

+ (id)apiObjectReferenceWithType:(OSPMemberType)type identity:(NSInteger)identity
{
    return [[self alloc] initWithType:type identity:identity];
}

- (id)initWithType:(OSPMemberType)initType identity:(NSInteger)identity
{
    self = [super initUnsafely];
    
    if (nil != self)
    {
        [self setType:initType];
        [self setIdentity:identity];
    }
    
    return self;
}

- (OSPMemberType)memberType
{
    return [self type];
}

@end
