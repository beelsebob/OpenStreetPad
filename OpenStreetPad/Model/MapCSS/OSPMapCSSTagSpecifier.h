//
//  OSPMapCSSTagSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

#import "OSPMapCSSSpecifier.h"
#import "OSPMapCSSTagSpec.h"

@interface OSPMapCSSTagSpecifier : OSPMapCSSSpecifier

@property (readwrite, retain) OSPMapCSSTagSpec *tag;

- (OSPMapCSSSpecifier *)specifierWithAPIObject:(OSPAPIObject *)object;

@end
