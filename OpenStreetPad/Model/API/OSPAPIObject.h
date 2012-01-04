//
//  OSPApiObject.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPCoordinateRect.h"

typedef enum
{
    OSPMemberTypeNode     = 0x0,
    OSPMemberTypeWay      = 0x1,
    OSPMemberTypeRelation = 0x2,
    OSPMemberTypeNone     = 0x3
} OSPMemberType;

@class OSPMap;

@class OSPAPIObjectReference;

@interface OSPAPIObject : NSObject <OSPBounded>

@property (readwrite, assign) NSInteger identity;
@property (readwrite, assign) NSUInteger version;
@property (readwrite, assign) NSUInteger changesetId;
@property (readwrite, strong) NSString *user;
@property (readwrite, assign) NSUInteger userId;
@property (readwrite, assign) BOOL visible;
@property (readwrite, strong) NSDate *timestamp;

@property (readwrite, copy  ) NSDictionary *tags;

@property (readwrite, copy  ) NSSet *parents;

@property (readwrite, weak) OSPMap *map;

@property (readonly) OSPMemberType memberType;

- (id)initUnsafely;

- (BOOL)isEqualToAPIObject:(OSPAPIObject *)object;

- (NSSet *)childObjects;
- (void)addParent:(OSPAPIObjectReference *)newParent;

@end
