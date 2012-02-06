//
//  Specifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

#import "OSPAPIObject.h"
#import "OSPMapCSSSize.h"
#import "OSPMapCSSUrl.h"

@interface OSPMapCSSSpecifier : NSObject <CPParseResult>

- (NSString *)stringValue;
- (OSPMapCSSSize *)sizeValue;
#if TARGET_OS_IPHONE
- (UIColor *)colourValue;
#endif
- (OSPMapCSSUrl *)urlValue;

@end
