//
//  OSPAPIObjectReference.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 29/08/2011.
//  Copyright (c) 2011 In The Beginning... All rights reserved.
//

#import "OSPAPIObject.h"

#import "OSPMember.h"

@interface OSPAPIObjectReference : OSPAPIObject

+ (id)apiObjectReferenceWithType:(OSPMemberType)type identity:(NSInteger)identity;
- (id)initWithType:(OSPMemberType)type identity:(NSInteger)identity;

@end
