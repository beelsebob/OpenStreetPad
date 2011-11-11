//
//  OSPRelation.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPRelation.h"

#import "OSPMember.h"

#import "OSPMap.h"

@implementation OSPRelation
{
    __strong NSMutableArray *members;
}

- (NSArray *)members
{
    @synchronized(self)
    {
        return members;
    }
}

- (void)setMembers:(NSArray *)newMembers
{
    @synchronized(self)
    {
        members = [newMembers mutableCopy];
    }
}

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setMembers:[NSArray array]];
    }
    
    return self;
}

- (void)addMember:(OSPMember *)member
{
    [member setRelation:self];
    [members addObject:member];
}

- (OSPCoordinateRect)bounds
{
    if ([[self members] count] > 0)
    {
        
        OSPCoordinateRect ownRect = [(OSPMember *)[[self members] objectAtIndex:0] bounds];
        for (OSPMember *member in [self members])
        {
            ownRect = OSPCoordinateRectUnion(ownRect, [member bounds]);
        }
        return ownRect;
    }
    else
    {
        return OSPCoordinateRectZero;
    }
}

- (OSPMemberType)memberType
{
    return OSPMemberTypeRelation;
}

- (NSSet *)childObjects
{
    NSMutableSet *childNodes = [NSMutableSet setWithCapacity:[[self members] count]];
    for (OSPMember *child in [self members])
    {
        id ch = [[self map] apiObjectOfType:[child referencedObjectType] withId:[child referencedObjectId]];
        if (nil != ch)
        {
            [childNodes addObject:ch];
        }
    }
    return childNodes;
}

@end
