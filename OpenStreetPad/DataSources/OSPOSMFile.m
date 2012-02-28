//
//  OSPOSMFileStore.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOSMFile.h"

#import "OSPOSMParser.h"

#import "OSPMap.h"

@interface OSPOSMFile () <OSPOSMParserDelegate>

@property (readwrite, strong) id<OSPDataProvider, OSPDataStore> cache;
@property (readwrite, strong) OSPOSMParser *parser;

@end

@implementation OSPOSMFile
{
    dispatch_queue_t parserQueue;
}

@synthesize path;

@synthesize parser;
@synthesize cache;

+ (id)osmFileWithPath:(NSString *)path
{
    return [[OSPOSMFile alloc] initWithPath:path];
}

- (id)initWithPath:(NSString *)initPath
{
    self = [super init];
    
    if (nil != self)
    {
        parserQueue = dispatch_queue_create("XML parser", DISPATCH_QUEUE_CONCURRENT);
        [self setPath:initPath];
        [self setCache:[[OSPMap alloc] init]];
    }
    
    return self;
}

- (void)dealloc
{
    dispatch_release(parserQueue);
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)bounds
{
    return [[self cache] objectsInBounds:bounds];
}

- (void)loadObjectsInBounds:(OSPCoordinateRect)bounds withOutset:(double)outsetSize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^()
    {
        NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:[self path]];
        [self setParser:[[OSPOSMParser alloc] initWithStream:stream]];
        [[self parser] setDelegate:self];
        dispatch_async(parserQueue, ^()
                       {
                           [[self parser] parse];
                       });
    });
}

- (void)parser:(OSPOSMParser *)parser didFindAPIObject:(OSPAPIObject *)object
{
    if ([[self cache] isKindOfClass:[OSPMap class]])
    {
        [object setMap:(OSPMap *)[self cache]];
    }
    [[self cache] addObject:object];
}

- (void)parser:(OSPOSMParser *)parser didFailWithError:(NSError *)error
{
}

- (void)parserDidEndDocument:(OSPOSMParser *)parser
{
    [[self delegate] dataSource:self didLoadObjectsInArea:OSPCoordinateRectMake(0.0, 0.0, 1.0, 1.0)];
}

@end
