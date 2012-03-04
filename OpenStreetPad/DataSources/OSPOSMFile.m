//
//  OSPOSMFile.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOSMFile.h"

#import "OSPOSMParser.h"
#import "OSPOSMWriter.h"

#import "OSPMap.h"

@interface OSPOSMFile () <OSPOSMParserDelegate>

@property (readwrite, strong) id<OSPDataProvider, OSPDataStore> cache;
@property (readwrite, strong) OSPOSMParser *parser;

@end

@implementation OSPOSMFile

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
        [self setPath:initPath];
        [self setCache:[[OSPMap alloc] init]];
    }
    
    return self;
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)bounds
{
    return [[self cache] objectsInBounds:bounds];
}

- (NSSet *)allObjects
{
    return [[self cache] allObjects];
}

- (void)loadObjectsInBounds:(OSPCoordinateRect)bounds withOutset:(double)outsetSize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^()
    {
        NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:[self path]];
        [self setParser:[[OSPOSMParser alloc] initWithStream:stream]];
        [[self parser] setDelegate:self];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^()
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

- (void)addObject:(id)apiObject
{
    [[self cache] addObject:apiObject];
}

- (void)save
{
    [[NSFileManager defaultManager] createFileAtPath:[self path] contents:[NSData data] attributes:nil];
    NSOutputStream *oStream = [NSOutputStream outputStreamToFileAtPath:[self path] append:NO];
    [oStream open];
    OSPOSMWriter *writer = [[OSPOSMWriter alloc] initWithStream:oStream];
    [writer writeDataProvider:[self cache]];
    [oStream close];
}

@end
