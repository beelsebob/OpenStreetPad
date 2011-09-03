//
//  OSPWay.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/08/2011.
//  Copyright 2011 In The Beginning... All rights reserved.
//

#import "OSPAPIObject.h"

@interface OSPWay : OSPAPIObject

@property (readwrite,copy) NSArray *nodes;

- (void)addNodeWithId:(NSInteger)nodeId;

@end
