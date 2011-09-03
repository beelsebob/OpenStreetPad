//
//  OSPRelation.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import "OSPAPIObject.h"

@class OSPMember;

@interface OSPRelation : OSPAPIObject

@property (readwrite,copy) NSArray *members;

- (void)addMember:(OSPMember *)member;

@end
