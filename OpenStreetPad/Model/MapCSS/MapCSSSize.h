//
//  Size.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

typedef enum
{
    OSPMapCSSUnitPt     ,
    OSPMapCSSUnitPx     ,
    OSPMapCSSUnitPercent,
} OSPMapCSSUnit;

OSPMapCSSUnit OSPMapCSSUnitFromNSString(NSString *s);
NSString *NSStringFromOSPMapCSSUnit(OSPMapCSSUnit u);

@interface MapCSSSize : NSObject <CPParseResult>

@property (readwrite, assign) float value;
@property (readwrite, assign) OSPMapCSSUnit unit;

@end
