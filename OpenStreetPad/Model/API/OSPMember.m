//
//  OSPMember.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMember.h"

#import "OSPRelation.h"
#import "OSPMap.h"

@implementation OSPMember
{
    OSPMemberType referencedObjectType;
    NSInteger referencedObjectId;
    __strong OSPAPIObject *referencedObject;
}

@synthesize role;
@synthesize relation;


- (OSPMemberType)referencedObjectType
{
    @synchronized(self)
    {
        return referencedObjectType;
    }
}

- (void)setReferencedObjectType:(OSPMemberType)newReferencedObjectType
{
    @synchronized(self)
    {
        referencedObjectType = newReferencedObjectType;
//        referencedObject = [[[self relation] map] apiObjectOfType:referencedObjectType withId:[self referencedObjectId]];
    }
}

- (NSInteger)referencedObjectId
{
    @synchronized(self)
    {
        return referencedObjectId;
    }
}

- (void)setReferencedObjectId:(NSInteger)newReferencedObjectId
{
    @synchronized(self)
    {
        referencedObjectId = newReferencedObjectId;
        
        referencedObject = [[[self relation] map] apiObjectOfType:referencedObjectType withId:[self referencedObjectId]];
    }
}

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setRole:@""];
    }
    
    return self;
}

+ (id)memberWithType:(OSPMemberType)memberType referencedObjectId:(NSInteger)referenceId role:(NSString *)role
{
    return [[self alloc] initWithType:memberType referencedObjectId:referenceId role:role];
}

- (id)initWithType:(OSPMemberType)memberType referencedObjectId:(NSInteger)referenceId role:(NSString *)initRole
{
    self = [super init];
    
    if (nil != self)
    {
        [self setReferencedObjectType:memberType];
        [self setReferencedObjectId:referenceId];
        [self setRole:initRole];
    }
    
    return self;
}

- (OSPAPIObject *)referencedObject
{
    if (nil == referencedObject)
    {
        referencedObject = [[[self relation] map] apiObjectOfType:referencedObjectType withId:referencedObjectId];
    }
    return referencedObject;
}

- (OSPCoordinateRect)bounds
{
    return [referencedObject bounds];
}

@end
