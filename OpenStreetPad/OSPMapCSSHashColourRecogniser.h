//
//  OSPMapCSSHashColourRecogniser.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "CoreParse.h"
#else
#import <CoreParse/CoreParse.h>
#endif

@interface OSPMapCSSHashColourRecogniser : NSObject <CPTokenRecogniser>

+ (id)hashColourRecogniser;

@end
