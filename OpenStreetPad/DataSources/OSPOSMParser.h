//
//  OSPOSMParser.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPAPIObject.h"

@class OSPOSMParser;

@protocol OSPOSMParserDelegate <NSObject>

- (void)parser:(OSPOSMParser *)parser didFindAPIObject:(OSPAPIObject *)object;
- (void)parser:(OSPOSMParser *)parser didFailWithError:(NSError *)error;
- (void)parserDidEndDocument:(OSPOSMParser *)parser;

@end

@interface OSPOSMParser : NSObject

@property (readwrite, weak) id<OSPOSMParserDelegate> delegate;

- (id)initWithStream:(NSInputStream *)stream;

- (void)parse;

@end
