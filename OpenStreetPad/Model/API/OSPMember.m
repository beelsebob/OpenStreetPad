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

@synthesize referencedObjectType;
@synthesize referencedObjectId;
@synthesize role;
@synthesize relation;

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
    return [[[self relation] map] apiObjectOfType:[self referencedObjectType] withId:[self referencedObjectId]];
}

- (OSPCoordinateRect)bounds
{
    return [[self referencedObject] bounds];
}

@end
