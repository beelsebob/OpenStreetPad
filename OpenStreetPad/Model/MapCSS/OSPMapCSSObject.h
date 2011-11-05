//
//  OSPMapCSSObject.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

typedef enum
{
    OSPMapCSSObjectTypeNode,
    OSPMapCSSObjectTypeWay,
    OSPMapCSSObjectTypeRelation,
    OSPMapCSSObjectTypeArea,
    OSPMapCSSObjectTypeLine,
    OSPMapCSSObjectTypeCanvas,
    OSPMapCSSObjectTypeAll
} OSPMapCSSObjectType;

NSString *NSStringFromOSPMapCSSObjectType(OSPMapCSSObjectType t);
OSPMapCSSObjectType OSPMapCSSObjectTypeFromNSString(NSString *s);

@interface OSPMapCSSObject : NSObject <CPParseResult>

@property (readwrite, assign) OSPMapCSSObjectType objectType;

@end
