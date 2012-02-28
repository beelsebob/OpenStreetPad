//
//  OSPMap.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPDataSource.h"
#import "OSPDataStore.h"

#import "OSPAPIObject.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"

@interface OSPMap : NSObject <OSPDataProvider, OSPDataStore>

- (OSPNode *)nodeWithId:(NSInteger)nodeId;
- (OSPWay *)wayWithId:(NSInteger)wayId;
- (OSPRelation *)relationWithId:(NSInteger)relationId;
- (OSPAPIObject *)apiObjectOfType:(OSPMemberType)type withId:(NSInteger)objectId;

@end
