//
//  OSPApiObject.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import "OSPAPIObject.h"

#import "OSPMap.h"

@implementation OSPAPIObject
{
    __strong NSMutableDictionary *tags;
}

@synthesize identity;
@synthesize version;
@synthesize changesetId;
@synthesize user;
@synthesize userId;
@synthesize visible;
@synthesize timestamp;

@synthesize map;

- (NSDictionary *)tags
{
    return tags;
}

- (void)setTags:(NSDictionary *)newTags
{
    tags = [newTags mutableCopy];
}

- (id)initUnsafely
{
    return [super init];
}

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setUser:@""];
        [self setTimestamp:[NSDate date]];
        [self setTags:[NSDictionary dictionary]];
    }
    
    return self;
}

- (OSPMemberType)memberType
{
    [NSException raise:@"Abstract method exception" format:@"-memberType is an abstract method, you must call it on one of the subclasses of OSPAPIObject"];
    return OSPMemberTypeNone;
}

- (OSPCoordinateRect)bounds
{
    [NSException raise:@"Abstract method exception" format:@"-bounds is an abstract method, you must call it on one of the subclasses of OSPMapObject or OSPAPIObject"];
    return OSPCoordinateRectZero;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OSPAPIObject class]])
    {
        OSPAPIObject *o = (OSPAPIObject *)object;
        return [self identity] == [o identity] && [o memberType] == [self memberType];
    }
    
    return NO;
}

- (BOOL)isEqualToAPIObject:(OSPAPIObject *)object
{
    OSPAPIObject *o = (OSPAPIObject *)object;
    return [self identity] == [o identity] && [o memberType] == [self memberType];
}

- (NSUInteger)hash
{
    return [self identity] << 2 + [self memberType];
}

@end
