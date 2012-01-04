//
//  OSPMember.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPAPIObject.h"

#import "OSPMap.h"

@class OSPRelation;

@interface OSPMember : NSObject

+ (id)memberWithType:(OSPMemberType)memberType referencedObjectId:(NSInteger)referenceId role:(NSString *)role;
- (id)initWithType:(OSPMemberType)memberType referencedObjectId:(NSInteger)referenceId role:(NSString *)role;

@property (readwrite, assign) OSPMemberType referencedObjectType;
@property (readwrite, assign) NSInteger referencedObjectId;
@property (readwrite, copy  ) NSString *role;
@property (readwrite, weak  ) OSPRelation *relation;

@property (readonly) OSPAPIObject *referencedObject;

@property (readonly) OSPCoordinateRect bounds;

@end
