//
//  OSPMapCSSHashColourRecogniser.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 20/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSHashColourRecogniser.h"

#import "OSPMapCSSHashColourToken.h"

@interface OSPMapCSSHashColourRecogniser ()

- (BOOL)interpretHex:(NSString *)hex into:(uint8_t *)c;
- (BOOL)interpetHexChar:(char)h into:(uint8_t *)v;

@end

@implementation OSPMapCSSHashColourRecogniser

+ (id)hashColourRecogniser
{
    return [[self alloc] init];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    return [self init];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    
}

- (CPToken *)recogniseTokenInString:(NSString *)tokenString currentTokenPosition:(NSUInteger *)tokenPosition
{
    NSUInteger remainingChars = [tokenString length] - *tokenPosition;
    if (remainingChars >= 7 &&
        [[tokenString substringWithRange:NSMakeRange(*tokenPosition, 1)] isEqualToString:@"#"])
    {
        NSString *redChars   = [tokenString substringWithRange:NSMakeRange(*tokenPosition + 1, 2)];
        NSString *greenChars = [tokenString substringWithRange:NSMakeRange(*tokenPosition + 3, 2)];
        NSString *blueChars  = [tokenString substringWithRange:NSMakeRange(*tokenPosition + 5, 2)];
        uint8_t red;
        uint8_t green;
        uint8_t blue;
        BOOL isValid = [self interpretHex:redChars into:&red];
        isValid &= [self interpretHex:greenChars into:&green];
        isValid &= [self interpretHex:blueChars into:&blue];
        if (isValid)
        {
            *tokenPosition += 7;
            return [OSPMapCSSHashColourToken tokenWithRed:red green:green blue:blue];
        }
    }
    return nil;
}

- (BOOL)interpretHex:(NSString *)hex into:(uint8_t *)c
{
    uint8_t f = 0;
    uint8_t s = 0;
    const char *cs = [hex cStringUsingEncoding:NSASCIIStringEncoding];
    BOOL isValid = [self interpetHexChar:cs[0] into:&f];
    isValid &= [self interpetHexChar:cs[1] into:&s];
    if (isValid)
    {
        *c = f * 16 + s;
    }
    return isValid;
}

- (BOOL)interpetHexChar:(char)h into:(uint8_t *)v
{
    if (h >= '0' && h <= '9')
    {
        *v = (h - '0') * 16;
    }
    else if (h >= 'a' && h <= 'f')
    {
        *v = (h - 'a' + 10) * 16;
    }
    else if (h >= 'A' && h <= 'F')
    {
        *v += (h - 'A' + 10) * 16;
    }
    else
    {
        return NO;
    }
    return YES;
}

@end
