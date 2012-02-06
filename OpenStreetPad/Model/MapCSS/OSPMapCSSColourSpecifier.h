//
//  ColourSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSpecifier.h"

@interface OSPMapCSSColourSpecifier : OSPMapCSSSpecifier

#if TARGET_OS_IPHONE
@property (readwrite, retain) UIColor *colour;

- (id)initWithColour:(UIColor *)colour;
#endif

@end
