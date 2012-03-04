//
//  OSPXMLWriter.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 03/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSPXMLWriter : NSObject

+ (id)xmlWriterWithOutputStream:(NSOutputStream *)outputStream encoding:(NSStringEncoding)encoding;
- (id)initWithOutputStream:(NSOutputStream *)outputStream encoding:(NSStringEncoding)encoding;

@property (strong) NSOutputStream *outputStream;

- (void)writeElement:(NSString *)element;
- (void)writeElement:(NSString *)element withAttributes:(NSDictionary *)attributes;

- (void)writeStartElement:(NSString *)element;
- (void)writeStartElement:(NSString *)element withAttributes:(NSDictionary *)attributes;
- (void)writeEndElement;

- (void)writeText:(NSString *)text;

@end
