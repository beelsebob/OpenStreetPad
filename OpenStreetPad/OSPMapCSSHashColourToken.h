//
//  OSPMapCSSHashColourToken.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

#import "CoreParse.h"
#else
#import <CoreParse/CoreParse.h>
#endif

@interface OSPMapCSSHashColourToken : CPToken

#if TARGET_OS_IPHONE
@property (readwrite,retain) UIColor *colour;
#endif

+ (id)tokenWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b;
- (id)initWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b;

@end
