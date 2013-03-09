//
//  BinaryTest.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSBinaryTest.h"

OSPMapCSSBinaryOperator OSPMapCSSBinaryOperatorFromNSString(NSString *s)
{
    if ([s isEqualToString:@"="])
    {
        return OSPMapCSSBinaryOperatorEquals;
    }
    else if ([s isEqualToString:@"=~"])
    {
        return OSPMapCSSBinaryOperatorMatches;
    }
    else if ([s isEqualToString:@"!="])
    {
        return OSPMapCSSBinaryOperatorNotEquals;
    }
    else if ([s isEqualToString:@"<"])
    {
        return OSPMapCSSBinaryOperatorLessThan;
    }
    else if ([s isEqualToString:@">"])
    {
        return OSPMapCSSBinaryOperatorGreaterThan;
    }
    else if ([s isEqualToString:@"<="])
    {
        return OSPMapCSSBinaryOperatorLessThanOrEqual;
    }
    else
    {
        return OSPMapCSSBinaryOperatorGreaterThanOrEqual;
    }
}

NSString *NSStringFromOSPMapCSSBinaryOperator(OSPMapCSSBinaryOperator o)
{
    switch (o) {
        case OSPMapCSSBinaryOperatorEquals:
            return @"=";
        case OSPMapCSSBinaryOperatorMatches:
            return @"=~";
        case OSPMapCSSBinaryOperatorLessThan:
            return @"<";
        case OSPMapCSSBinaryOperatorNotEquals:
            return @"!=";
        case OSPMapCSSBinaryOperatorGreaterThan:
            return @">";
        case OSPMapCSSBinaryOperatorLessThanOrEqual:
            return @"<=";
        case OSPMapCSSBinaryOperatorGreaterThanOrEqual:
            return @">=";
    }
}

@implementation OSPMapCSSBinaryTest

@synthesize tagName;
@synthesize operator;
@synthesize value;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setTagName:[[syntaxTree children][0] description]];
        [self setOperator:OSPMapCSSBinaryOperatorFromNSString([[[syntaxTree children][1] children][0] keyword])];
        CPToken *t = [[syntaxTree children][2] children][0];
        if ([t isKindOfClass:[CPIdentifierToken class]])
        {
            [self setValue:[(CPIdentifierToken *)t identifier]];
        }
        else if ([t isKindOfClass:[CPNumberToken class]])
        {
            [self setValue:[NSString stringWithFormat:@"%@", [(CPNumberToken *)t number]]];
        }
        else
        {
            [self setValue:[(CPQuotedToken *)t content]];
        }
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@ %@ \"%@\"]", [self tagName], NSStringFromOSPMapCSSBinaryOperator([self operator]), [self value]];
}

- (BOOL)matchesObject:(OSPAPIObject *)object
{
    NSString *objectValue = [object valueForTag:tagName];
    switch ([self operator])
    {
        case OSPMapCSSBinaryOperatorEquals:
            return [objectValue isEqualToString:value];
        case OSPMapCSSBinaryOperatorNotEquals:
            return ![objectValue isEqualToString:value];
        case OSPMapCSSBinaryOperatorMatches:
        {
            NSError *err = nil;
            NSRegularExpression *e = [NSRegularExpression regularExpressionWithPattern:value options:0 error:&err];
            return [e numberOfMatchesInString:objectValue options:NSMatchingAnchored range:NSMakeRange(0, [objectValue length])] > 0;
        }
        case OSPMapCSSBinaryOperatorLessThan:
            return [objectValue floatValue] < [value floatValue];
        case OSPMapCSSBinaryOperatorGreaterThan:
            return [objectValue floatValue] > [value floatValue];
        case OSPMapCSSBinaryOperatorLessThanOrEqual:
            return [objectValue floatValue] <= [value floatValue];
        case OSPMapCSSBinaryOperatorGreaterThanOrEqual:
            return [objectValue floatValue] >= [value floatValue];
    }
}

@end
