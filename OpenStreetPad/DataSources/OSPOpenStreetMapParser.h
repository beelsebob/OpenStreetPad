//
//  OSPOpenStreetMapParser.h
//  
//
//  Created by Thomas Davie on 04/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPAPIObject.h"

@class OSPOpenStreetMapParser;

@protocol OSPOpenStreetMapParserDelegate <NSObject>

- (void)parser:(OSPOpenStreetMapParser *)parser didFindAPIObject:(OSPAPIObject *)object;
- (void)parser:(OSPOpenStreetMapParser *)parser didFailWithError:(NSError *)error;
- (void)parserDidEndDocument:(OSPOpenStreetMapParser *)parser;

@end

@interface OSPOpenStreetMapParser : NSObject

@property (readwrite, weak) id<OSPOpenStreetMapParserDelegate> delegate;

- (id)initWithStream:(NSInputStream *)stream;

- (void)parse;

@end
