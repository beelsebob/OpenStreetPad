//
//  OSPMapServer.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 07/08/2011.
//  Copyright 2011 Thomas Davie All rights reserved.
//

#import "OSPMapServer.h"

#import "OSPMap.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"
#import "OSPAPIObjectReference.h"

#import "OSPNonRectangularArea.h"
#import "OSPValue.h"

typedef enum
{
    OSPRequestTypeCapabilities = 0,
    OSPRequestTypeMapArea         ,
} OSPRequestType;

@class OSPConnection;

@protocol OSPConnectionDelegate <NSObject>

- (void)connection:(OSPConnection *)connection didReceiveAPIObject:(OSPAPIObject *)object;
- (void)connectionDidFinishLoading:(OSPConnection *)connection;
- (void)connection:(OSPConnection *)connection didFailWithError:(NSError *)err;

@end

@interface OSPConnection : NSObject <NSStreamDelegate, NSXMLParserDelegate, NSURLConnectionDelegate>

@property (readwrite, strong) NSURLConnection *connection;
@property (readwrite, strong) NSURLRequest *request;
@property (readwrite, assign) OSPRequestType requestType;
@property (readwrite, strong) NSXMLParser *parser;
@property (readwrite, strong) NSOutputStream *parserStream;
@property (readwrite, assign, getter=isCompleted) BOOL completed;
@property (readwrite, strong) NSMutableData *data;
@property (readwrite, weak  ) id<OSPConnectionDelegate> delegate;

@property (readwrite, assign) OSPCoordinateRect mapArea;

@property (readwrite, strong) NSMutableDictionary *currentObjectTags;
@property (readwrite, strong) OSPAPIObject *currentObject;

@property (readwrite, copy  ) NSArray *receivedObjects;

- (void)attemptToWriteToStream;

- (void)setupAPIObject:(OSPAPIObject *)object withAttributes:(NSDictionary *)attributes;

- (void)notifyDelegateParserDidEndDocument;

@end

@implementation OSPConnection
{
    __strong NSMutableArray *receivedObjects;
}

@synthesize connection;
@synthesize request;
@synthesize requestType;
@synthesize parser;
@synthesize parserStream;
@synthesize completed;
@synthesize data;
@synthesize delegate;

@synthesize currentObject;
@synthesize currentObjectTags;

@synthesize mapArea;

- (NSArray *)receivedObjects
{
    return receivedObjects;
}

- (void)setReceivedObjects:(NSArray *)newReceivedObjects
{
    receivedObjects = [newReceivedObjects mutableCopy];
}

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        [self setCompleted:NO];
        [self setData:[NSMutableData data]];
        [self setReceivedObjects:[NSArray array]];
    }
    
    return self;
}

- (void)attemptToWriteToStream
{
    if ([[self data] length] > 0)
    {
        NSUInteger written = [[self parserStream] write:[[self data] bytes] maxLength:[[self data] length]];
        [[self data] replaceBytesInRange:NSMakeRange(0,written) withBytes:"" length:0];
    }
}

- (void)stream:(NSStream *)s handleEvent:(NSStreamEvent)event
{
    if (NSStreamEventHasSpaceAvailable == event)
    {
        if ([self isCompleted] && [[self data] length] == 0)
        {
            [[self parserStream] close];
        }
        else
        {
            [self attemptToWriteToStream];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
    [[self data] appendData:d];
    [self attemptToWriteToStream];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[self delegate] connection:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self setCompleted:YES];
    [self attemptToWriteToStream];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    @autoreleasepool
    {
        if ([elementName isEqualToString:@"tag"])
        {
            [[self currentObjectTags] setObject:[attributeDict objectForKey:@"v"] forKey:[attributeDict objectForKey:@"k"]];
        }
        else if ([elementName isEqualToString:@"node"])
        {
            OSPNode *node = [[OSPNode alloc] init];
            
            [self setCurrentObject:node];
            [self setCurrentObjectTags:[NSMutableDictionary dictionary]];
            [self setupAPIObject:node withAttributes:attributeDict];
            [node setLocation:CLLocationCoordinate2DMake([[attributeDict objectForKey:@"lat"] doubleValue], [[attributeDict objectForKey:@"lon"] doubleValue])];
        }
        else if ([elementName isEqualToString:@"nd"])
        {
            [(OSPWay *)[self currentObject] addNodeWithId:[[attributeDict objectForKey:@"ref"] integerValue]];
        }
        else if ([elementName isEqualToString:@"way"])
        {
            [self setCurrentObject:[[OSPWay alloc] init]];
            [self setCurrentObjectTags:[NSMutableDictionary dictionary]];
            
            [self setupAPIObject:[self currentObject] withAttributes:attributeDict];
        }
        else if ([elementName isEqualToString:@"relation"])
        {
            OSPRelation *rel = [[OSPRelation alloc] init];
            [self setCurrentObject:rel];
            [self setCurrentObjectTags:[NSMutableDictionary dictionary]];
            
            [self setupAPIObject:rel withAttributes:attributeDict];
        }
        else if ([elementName isEqualToString:@"member"])
        {
            NSString *typeString = [attributeDict objectForKey:@"type"];
            OSPMemberType t = [typeString isEqualToString:@"node"] ? OSPMemberTypeNode : [typeString isEqualToString:@"way"] ? OSPMemberTypeWay : OSPMemberTypeRelation;
            [(OSPRelation *)[self currentObject] addMember:[OSPMember memberWithType:t referencedObjectId:[[attributeDict objectForKey:@"ref"] integerValue] role:[attributeDict objectForKey:@"role"]]];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    @autoreleasepool
    {
        if (nil != [self currentObject] && ([elementName isEqualToString:@"node"] || [elementName isEqualToString:@"way"] || [elementName isEqualToString:@"relation"]))
        {
            [[self currentObject] setTags:[self currentObjectTags]];
            [receivedObjects addObject:[self currentObject]];
            [[self delegate] connection:self didReceiveAPIObject:[self currentObject]];
            [self setCurrentObject:nil];
        }
    }
}

- (void)setupAPIObject:(OSPAPIObject *)object withAttributes:(NSDictionary *)attributes
{
    [object setChangesetId:[[attributes objectForKey:@"changeset"] integerValue]];
    [object setIdentity:[[attributes objectForKey:@"id"] integerValue]];
    [object setUserId:[[attributes objectForKey:@"uid"] integerValue]];
    [object setUser:[attributes objectForKey:@"user"]];
    [object setVersion:[[attributes objectForKey:@"version"] integerValue]];
    [object setVisible:[[attributes objectForKey:@"visible"] boolValue]];
}

- (void)parserDidEndDocument:(NSXMLParser *)p
{
    [self performSelectorOnMainThread:@selector(notifyDelegateParserDidEndDocument) withObject:nil waitUntilDone:NO];
}

- (void)notifyDelegateParserDidEndDocument
{
    [[self delegate] connectionDidFinishLoading:self];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [[self delegate] connection:self didFailWithError:parseError];
}

@end

#define OSPUserAgentName    @"OpenStreetPad"
#define OSPUserAgentVersion @"0.1"

#define OSPMapServerMaxSimultaneousConnections 2

@interface OSPMapServer () <OSPConnectionDelegate>
{
    dispatch_queue_t parserQueue;
}

@property (readwrite, copy  ) NSURL *serverURL;
@property (readwrite, strong) OSPMap *mapCache;
@property (readwrite, strong) NSMutableArray *currentConnections;
@property (readwrite, strong) NSMutableArray *connectionQueue;

@property (readwrite, strong) OSPNonRectangularArea *requestedArea;

- (void)makeRequestForURL:(NSURL *)url ofType:(OSPRequestType)type withArea:(OSPCoordinateRect)area;
- (void)queueConnection:(OSPConnection *)rec;
- (void)popConnectionQueue;

@end

@implementation OSPMapServer

@synthesize serverURL;
@synthesize mapCache;
@synthesize delegate;
@synthesize currentConnections;
@synthesize connectionQueue;
@synthesize requestedArea;

+ (id)serverWithURL:(NSURL *)serverURL
{
    return [[self alloc] initWithURL:serverURL];
}

- (id)initWithURL:(NSURL *)initServerURL
{
    self = [super init];
    
    if (nil != self)
    {
        parserQueue = dispatch_queue_create("XML parser", DISPATCH_QUEUE_CONCURRENT);
        [self setServerURL:initServerURL];
        [self setMapCache:[[OSPMap alloc] init]];
        [self setRequestedArea:[OSPNonRectangularArea emptyArea]];
        [self setCurrentConnections:[[NSMutableArray alloc] initWithCapacity:OSPMapServerMaxSimultaneousConnections]];
        [self setConnectionQueue:[NSMutableArray array]];
    }
    
    return self;
}

- (id)init
{
    return [self initWithURL:[NSURL URLWithString:@"http://api.openstreetmap.org"]];
}

- (void)dealloc
{
    dispatch_release(parserQueue);
}

- (NSSet *)objectsInBounds:(OSPCoordinateRect)bounds
{
    return [[self mapCache] objectsInBounds:bounds];
}

- (void)loadObjectsInBounds:(OSPCoordinateRect)bounds withOutset:(double)outsetSize
{
    OSPNonRectangularArea *rectanglesToLoad = [[OSPNonRectangularArea areaWithRects:[NSArray arrayWithObject:[OSPValue valueWithRect:bounds]]] areaBySubtractingArea:[self requestedArea]];
    
    NSArray *bigEnoughRects = [[rectanglesToLoad allRects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^ BOOL (OSPValue *rect, id bindings)
                                                                                        {
                                                                                            OSPCoordinateRect r = [rect rectValue];
                                                                                            return r.size.x > 0.000005 && r.size.y > 0.000005;
                                                                                        }]];
    
    if ([bigEnoughRects count] > 0)
    {
        rectanglesToLoad = [[OSPNonRectangularArea areaWithRects:[NSArray arrayWithObject:[OSPValue valueWithRect:OSPCoordinateRectOutset(bounds, outsetSize, outsetSize)]]] areaBySubtractingArea:[self requestedArea]];
        bigEnoughRects = [[rectanglesToLoad allRects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^ BOOL (OSPValue *rect, id bindings)
                                                                                   {
                                                                                       OSPCoordinateRect r = [rect rectValue];
                                                                                       return r.size.x > 0.000005 && r.size.y > 0.000005;
                                                                                   }]];
        
        for (OSPValue *rectValue in bigEnoughRects)
        {
            OSPCoordinateRect rect = [rectValue rectValue];
            
            CLLocationCoordinate2D from = OSPCoordinate2DUnproject(OSPCoordinateRectGetMinCoord(rect));
            CLLocationCoordinate2D to = OSPCoordinate2DUnproject(OSPCoordinateRectGetMaxCoord(rect));
            
            NSURL *mapURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/0.6/map?bbox=%f,%f,%f,%f", [self serverURL], from.longitude, to.latitude, to.longitude, from.latitude]];
            
            [self makeRequestForURL:mapURL ofType:OSPRequestTypeMapArea withArea:rect];
        }
    }
}

- (void)makeRequestForURL:(NSURL *)url ofType:(OSPRequestType)type withArea:(OSPCoordinateRect)area
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setValue:OSPUserAgentName @"/" OSPUserAgentVersion forHTTPHeaderField:@"User-Agent"];
        
    OSPConnection *rec = [[OSPConnection alloc] init];
    [rec setMapArea:area];
    [rec setRequest:req];
    [rec setRequestType:type];
    [rec setDelegate:self];
    [self queueConnection:rec];
    [[self requestedArea] addRect:area];
}

- (void)queueConnection:(OSPConnection *)newConnection
{
    [[self connectionQueue] addObject:newConnection];
    [self popConnectionQueue];
}

- (void)popConnectionQueue
{
    while ([[self currentConnections] count] < OSPMapServerMaxSimultaneousConnections && [[self connectionQueue] count] > 0)
    {
        OSPConnection *rec = [[self connectionQueue] objectAtIndex:0];
        [[self connectionQueue] removeObjectAtIndex:0];
        [[self currentConnections] addObject:rec];
        [rec setConnection:[NSURLConnection connectionWithRequest:[rec request] delegate:rec]];
        [[rec connection] start];
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 4096);
        NSInputStream *iStream = (__bridge_transfer NSInputStream *)readStream;
        NSOutputStream *oStream = (__bridge_transfer NSOutputStream *)writeStream;
        [oStream setDelegate:rec];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [iStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        [oStream scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        [iStream open];
        [oStream open];
        [rec setParserStream:oStream];
        NSXMLParser *parser = [[NSXMLParser alloc] initWithStream:iStream];
        [parser setDelegate:rec];
        [rec setParser:parser];
        dispatch_async(parserQueue, ^()
                       {
                           [parser parse];
                       });
    }
}

- (void)connection:(OSPConnection *)connection didReceiveAPIObject:(OSPAPIObject *)object
{
    [object setMap:[self mapCache]];
    [[self mapCache] addObject:object];
}

- (void)connectionDidFinishLoading:(OSPConnection *)connection
{
    for (OSPAPIObject *o in [connection receivedObjects])
    {
        OSPAPIObjectReference *ref = [[OSPAPIObjectReference alloc] initWithType:[o memberType] identity:[o identity]];
        for (OSPAPIObject *child in [o childObjects])
        {
            [child addParent:ref];
        }
    }
    
    [[self delegate] mapServer:self didLoadObjectsInArea:[connection mapArea]];
    [[self currentConnections] removeObject:connection];
    [self popConnectionQueue];
}

- (void)connection:(OSPConnection *)connection didFailWithError:(NSError *)err
{
    [[self currentConnections] removeObject:connection];
    [self popConnectionQueue];
}

@end
