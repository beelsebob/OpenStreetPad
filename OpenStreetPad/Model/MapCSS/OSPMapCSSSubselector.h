//
//  Subselector.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 02/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

#import "OSPMapCSSClass.h"
#import "OSPMapCSSObject.h"

#import "OSPAPIObject.h"

@interface OSPMapCSSSubselector : NSObject <CPParseResult>

@property (readwrite, assign) OSPMapCSSObjectType objectType;
@property (readwrite, assign, getter=isConstrainedToZoomRange) BOOL constrainedToZoomRange;
@property (readwrite, assign) float minimumZoom;
@property (readwrite, assign) float maximumZoom;
@property (readwrite, copy) NSArray *tests;
@property (readwrite, strong) OSPMapCSSClass *requiredClass;

- (BOOL)matchesObject:(OSPAPIObject *)object;

@end
