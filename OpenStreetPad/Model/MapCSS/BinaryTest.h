//
//  BinaryTest.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Test.h"

#import "Tag.h"

typedef enum 
{
    OSPMapCSSBinaryOperatorEquals,
    OSPMapCSSBinaryOperatorNotEquals,
    OSPMapCSSBinaryOperatorMatches,
    OSPMapCSSBinaryOperatorGreaterThan,
    OSPMapCSSBinaryOperatorLessThan,
    OSPMapCSSBinaryOperatorGreaterThanOrEqual,
    OSPMapCSSBinaryOperatorLessThanOrEqual
} OSPMapCSSBinaryOperator;

OSPMapCSSBinaryOperator OSPMapCSSBinaryOperatorFromNSString(NSString *s);
NSString *NSStringFromOSPMapCSSBinaryOperator(OSPMapCSSBinaryOperator o);

@interface BinaryTest : Test

@property (readwrite, strong) Tag *tag;
@property (readwrite, assign) OSPMapCSSBinaryOperator operator;
@property (readwrite, copy) NSString *value;

@end
