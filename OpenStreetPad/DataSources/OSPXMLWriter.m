//
//  OSPXMLWriter.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 03/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPXMLWriter.h"

#import "NSString+XMLEscaping.h"

@interface OSPXMLWriter ()

@property (assign) NSStringEncoding encoding;
@property (strong) NSMutableArray *elementStack;
@property (assign,getter=hasStarted) BOOL started;
@property (assign,getter=hasWrittenFullEnclosingTag) BOOL writtenFullEnclosingTag;

- (void)writeStartIfNecessary;
- (void)endEnclosingTagIfNecessary;

@end

NSString *XMLEncodingNameFromNSStringEncoding(NSStringEncoding enc);

@implementation OSPXMLWriter

@synthesize outputStream;
@synthesize encoding;
@synthesize elementStack;
@synthesize started;
@synthesize writtenFullEnclosingTag;

+ (id)xmlWriterWithOutputStream:(NSOutputStream *)outputStream encoding:(NSStringEncoding)encoding
{
    return [[self alloc] initWithOutputStream:outputStream encoding:encoding];
}

- (id)initWithOutputStream:(NSOutputStream *)initOutputStream encoding:(NSStringEncoding)initEncoding
{
    self = [super init];
    
    if (nil != self)
    {
        [self setOutputStream:initOutputStream];
        [self setEncoding:initEncoding];
        [self setElementStack:[NSMutableArray array]];
        [self setStarted:NO];
        [self setWrittenFullEnclosingTag:YES];
    }
    
    return self;
}

- (void)writeStartIfNecessary
{
    if (![self hasStarted])
    {
        NSData *encodedString = [[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"%@\"?>", XMLEncodingNameFromNSStringEncoding([self encoding])] dataUsingEncoding:[self encoding]];
        NSUInteger remainingLength = [encodedString length];
        while (remainingLength > 0)
        {
            remainingLength -= [[self outputStream] write:[encodedString bytes] maxLength:remainingLength];
        }
        [self setStarted:YES];
    }
}

- (void)endEnclosingTagIfNecessary
{
    if (![self hasWrittenFullEnclosingTag])
    {
        NSData *encodedString = [@">" dataUsingEncoding:[self encoding]];
        NSUInteger remainingLength = [encodedString length];
        while (remainingLength > 0)
        {
            remainingLength -= [[self outputStream] write:[encodedString bytes] maxLength:remainingLength];
        }
        [self setWrittenFullEnclosingTag:YES];
    }
}

- (void)writeElement:(NSString *)element
{
    [self writeElement:element withAttributes:@{}];
}

- (void)writeElement:(NSString *)element withAttributes:(NSDictionary *)attributes
{
    [self writeStartIfNecessary];
    [self endEnclosingTagIfNecessary];
    NSMutableString *s = [NSMutableString stringWithFormat:@"<%@ ", element];
    for (NSString *key in attributes)
    {
        [s appendFormat:@"%@=\"%@\" ", key, [attributes[key] stringByAddingXMLEscaping]];
    }
    [s appendString:@"/>"];
    NSData *encodedString = [s dataUsingEncoding:[self encoding]];
    NSUInteger remainingLength = [encodedString length];
    while (remainingLength > 0)
    {
        remainingLength -= [[self outputStream] write:[encodedString bytes] maxLength:remainingLength];
    }
}

- (void)writeStartElement:(NSString *)element
{
    [self writeStartElement:element withAttributes:@{}];
}

- (void)writeStartElement:(NSString *)element withAttributes:(NSDictionary *)attributes
{
    [self writeStartIfNecessary];
    [self endEnclosingTagIfNecessary];
    [elementStack addObject:element];
    NSMutableString *s = [NSMutableString stringWithFormat:@"<%@ ", element];
    for (NSString *key in attributes)
    {
        [s appendFormat:@"%@=\"%@\" ", key, [attributes[key] stringByAddingXMLEscaping]];
    }
    [self setWrittenFullEnclosingTag:NO];
    NSData *encodedString = [s dataUsingEncoding:[self encoding]];
    NSUInteger remainingLength = [encodedString length];
    while (remainingLength > 0)
    {
        NSInteger written = [[self outputStream] write:[encodedString bytes] maxLength:remainingLength];
        remainingLength -= written;
    }
}

- (void)writeEndElement
{
    NSData *encodedString;
    if ([self hasWrittenFullEnclosingTag])
    {
        encodedString = [[NSString stringWithFormat:@"</%@>", [elementStack lastObject]] dataUsingEncoding:[self encoding]];
    }
    else
    {
        encodedString = [@"/>" dataUsingEncoding:[self encoding]];
    }
    [self setWrittenFullEnclosingTag:YES];
    NSUInteger remainingLength = [encodedString length];
    while (remainingLength > 0)
    {
        remainingLength -= [[self outputStream] write:[encodedString bytes] maxLength:remainingLength];
    }
    [elementStack removeLastObject];
}

- (void)writeText:(NSString *)text
{
    [self writeStartIfNecessary];
    [self endEnclosingTagIfNecessary];
    NSData *encodedString = [[text stringByAddingXMLEscaping] dataUsingEncoding:[self encoding]];
    NSUInteger remainingLength = [encodedString length];
    while (remainingLength > 0)
    {
        remainingLength -= [[self outputStream] write:[encodedString bytes] maxLength:remainingLength];
    }
}

@end

NSString *XMLEncodingNameFromNSStringEncoding(NSStringEncoding enc)
{
    switch (enc)
    {
        case NSUTF8StringEncoding:
        case NSASCIIStringEncoding:
            return @"UTF-8";
        case NSUTF16StringEncoding:
        case NSUTF16BigEndianStringEncoding:
        case NSUTF16LittleEndianStringEncoding:
            return @"UTF-16";
        case NSUTF32StringEncoding:
        case NSUTF32BigEndianStringEncoding:
        case NSUTF32LittleEndianStringEncoding:
            return @"UTF-32";
    }
    return @"";
}

