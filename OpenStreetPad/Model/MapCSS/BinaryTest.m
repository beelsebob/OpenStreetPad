//
//  BinaryTest.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "BinaryTest.h"

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

@implementation BinaryTest

@synthesize tag;
@synthesize operator;
@synthesize value;

- (id)initWithSyntaxTree:(CPSyntaxTree *)syntaxTree
{
    self = [super initWithSyntaxTree:syntaxTree];
    
    if (nil != self)
    {
        [self setTag:[[syntaxTree children] objectAtIndex:0]];
        [self setOperator:OSPMapCSSBinaryOperatorFromNSString([[[[[syntaxTree children] objectAtIndex:1] children] objectAtIndex:0] keyword])];
        [self setValue:[[[[[syntaxTree children] objectAtIndex:2] children] objectAtIndex:0] content]];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@ %@ \"%@\"]", [self tag], NSStringFromOSPMapCSSBinaryOperator([self operator]), [self value]];
}

- (BOOL)matchesObject:(OSPAPIObject *)object
{
    NSString *objectValue = [[object tags] objectForKey:[[self tag] description]];
    switch ([self operator])
    {
        case OSPMapCSSBinaryOperatorEquals:
//            NSLog(@"Matching object against %@ and returning %d:\n%@", self, [objectValue isEqualToString:[self value]], [object tags]);
            return [objectValue isEqualToString:[self value]];
        case OSPMapCSSBinaryOperatorNotEquals:
//            NSLog(@"Matching object against %@ and returning %d:\n%@", self, ![objectValue isEqualToString:[self value]], [object tags]);
            return ![objectValue isEqualToString:[self value]];
        case OSPMapCSSBinaryOperatorMatches:
        {
            NSError *err = nil;
            NSRegularExpression *e = [NSRegularExpression regularExpressionWithPattern:[self value] options:0 error:&err];
//            NSLog(@"Matching object against %@ and returning %d:\n%@", self, ([e numberOfMatchesInString:objectValue options:NSMatchingAnchored range:NSMakeRange(0, [objectValue length])] > 0), object);
            return [e numberOfMatchesInString:objectValue options:NSMatchingAnchored range:NSMakeRange(0, [objectValue length])] > 0;
        }
        case OSPMapCSSBinaryOperatorLessThan:
//            NSLog(@"Matching object against %@ and returning %d:\n%@", self, [objectValue floatValue] < [[self value] floatValue], [object tags]);
            return [objectValue floatValue] < [[self value] floatValue];
        case OSPMapCSSBinaryOperatorGreaterThan:
//            NSLog(@"Matching object against %@ and returning %d:\n%@", self, [objectValue floatValue] > [[self value] floatValue], [object tags]);
            return [objectValue floatValue] > [[self value] floatValue];
        case OSPMapCSSBinaryOperatorLessThanOrEqual:
//            NSLog(@"Matching object against %@ and returning %d:\n%@", self, [objectValue floatValue] <= [[self value] floatValue], [object tags]);
            return [objectValue floatValue] <= [[self value] floatValue];
        case OSPMapCSSBinaryOperatorGreaterThanOrEqual:
//            NSLog(@"Matching object against %@ and returning %d:\n%@", self, [objectValue floatValue] >= [[self value] floatValue], [object tags]);
            return [objectValue floatValue] >= [[self value] floatValue];
    }
}

@end
