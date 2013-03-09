//
//  OSPOpenStreetMapPBFParser.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 21/04/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOpenStreetMapPBFParser.h"

#import "Fileformat.pb.h"
#import "Osmformat.pb.h"

#import "NSData+ZipCompression.h"
#import "PSYEnumerable.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"

OSPMemberType OSPMemberTypeFromRelation_MemberType(Relation_MemberType t);

OSPMemberType OSPMemberTypeFromRelation_MemberType(Relation_MemberType t)
{
    switch (t)
    {
        case Relation_MemberTypeNode:     return OSPMemberTypeNode;
        case Relation_MemberTypeWay:      return OSPMemberTypeWay;
        case Relation_MemberTypeRelation: return OSPMemberTypeRelation;
    }
}

@interface OSPOpenStreetMapPBFParser () <NSStreamDelegate>

@property (readwrite, strong) NSInputStream *stream;

@property (readwrite, strong) NSMutableData *accumulatedData;
@property (readwrite, strong) BlobHeader *header;

- (BOOL)attemptToReadHeader;
- (BOOL)attemptToReadBody;

- (void)processNodes:(PrimitiveGroup *)group
         stringTable:(NSArray *)stringTable
           latOffset:(double)latOffset
           lonOffset:(double)lonOffset
         granularity:(double)granularity
     dateGranularity:(double)dateGranularity;
- (void)processDenseNodes:(PrimitiveGroup *)group
              stringTable:(NSArray *)stable
                latOffset:(double)latOffset
                lonOffset:(double)lonOffset
              granularity:(double)granularity
          dateGranularity:(double)dateGranularity;
- (void)processWays:(PrimitiveGroup *)group
        stringTable:(NSArray *)stringTable
    dateGranularity:(double)dateGranularity;
- (void)processRelations:(PrimitiveGroup *)group
             stringTable:(NSArray *)stringTable
         dateGranularity:(double)dateGranularity;

@end

@implementation OSPOpenStreetMapPBFParser

@synthesize stream = _stream;

@synthesize accumulatedData = _accumulatedData;
@synthesize header = _header;

- (id)initWithStream:(NSInputStream *)stream
{
    self = [super initWithStream:stream];
    
    if (nil != self)
    {
        [self setStream:stream];
    }
    
    return self;
}

- (void)parse
{
    [self setAccumulatedData:[NSMutableData data]];
    [[self stream] setDelegate:self];
    [[self stream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[self stream] open];
    [[NSRunLoop currentRunLoop] run];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode)
    {
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t bytes[1024];
            unsigned int len = 0;
            len = [[self stream] read:bytes maxLength:sizeof(bytes)];
            if (len > 0)
            {
                [[self accumulatedData] appendBytes:bytes length:len];
                BOOL processedData = NO;
                do
                {
                    if (nil == [self header])
                    {
                        processedData = [self attemptToReadHeader];
                    }
                    
                    if (nil != [self header])
                    {
                        processedData = [self attemptToReadBody];
                    }
                }
                while (processedData);
            }
            break;
        }
        case NSStreamEventEndEncountered:
            [[self delegate] parserDidEndDocument:self];
            break;
        case NSStreamEventErrorOccurred:
            [[self delegate] parser:self didFailWithError:[NSError errorWithDomain:@"Read Error" code:0 userInfo:nil]];
            break;
        default:
            break;
    }
}

- (BOOL)attemptToReadHeader
{
    if ([[self accumulatedData] length] <= sizeof(uint32_t))
    {
        return NO;
    }
    
    uint32_t len;
    [[self accumulatedData] getBytes:&len length:sizeof(uint32_t)];
    len = CFSwapInt32(len);
    
    if ([[self accumulatedData] length] < sizeof(uint32_t) + len)
    {
        return NO;
    }
    
    [self setHeader:[BlobHeader parseFromData:[[self accumulatedData] subdataWithRange:NSMakeRange(sizeof(uint32_t), len)]]];
    [[self accumulatedData] replaceBytesInRange:NSMakeRange(0, len + sizeof(uint32_t)) withBytes:NULL length:0];
    
    return YES;
}

#define NANO_DEGREE 0.000000001
#define MILLI       0.001

#define DEFAULT_LAT_OFFSET 0
#define DEFAULT_LON_OFFSET 0
#define DEFAULT_GRANULARITY 100
#define DEFAULT_DATE_GRANULARITY 1000

- (BOOL)attemptToReadBody
{
    if ([[self header] datasize] > [[self accumulatedData] length])
    {
        return NO;
    }
    
    NSRange blobRange = NSMakeRange(0, [[self header] datasize]);
    Blob *blob = [Blob parseFromData:[[self accumulatedData] subdataWithRange:blobRange]];
    
    NSData *blobData = [blob hasZlibData] ? [[blob zlibData] dataByDecompressingZip] : [blob data];
    
    NSString *headerType = [[self header] type];
    if ([headerType isEqualToString:@"OSMData"])
    {
        PrimitiveBlock *pb = [PrimitiveBlock parseFromData:blobData];
        NSArray *sTable = [[pb stringtable] sList];
        NSMutableArray *stringTable = [NSMutableArray arrayWithCapacity:[sTable count]];
        for (NSData *stringData in sTable)
        {
            [stringTable addObject:[[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding]];
        }
        
        double latOffset = NANO_DEGREE * ([pb hasLatOffset] ? [pb latOffset] : DEFAULT_LAT_OFFSET);
        double lonOffset = NANO_DEGREE * ([pb hasLonOffset] ? [pb lonOffset] : DEFAULT_LON_OFFSET);
        double granularity = NANO_DEGREE * ([pb hasGranularity] ? [pb granularity] : DEFAULT_GRANULARITY);
        double dateGranularity = MILLI * ([pb hasDateGranularity] ? [pb dateGranularity] : DEFAULT_DATE_GRANULARITY);
        
        for (PrimitiveGroup *group in [pb primitivegroupList])
        {
            [self processNodes:     group stringTable:stringTable latOffset:latOffset lonOffset:lonOffset granularity:granularity dateGranularity:dateGranularity];
            [self processDenseNodes:group stringTable:stringTable latOffset:latOffset lonOffset:lonOffset granularity:granularity dateGranularity:dateGranularity];
            [self processWays:      group stringTable:stringTable dateGranularity:dateGranularity];
            [self processRelations: group stringTable:stringTable dateGranularity:dateGranularity];
        }
    }
    
    [[self accumulatedData] replaceBytesInRange:blobRange withBytes:NULL length:0];
    [self setHeader:nil];
    
    return YES;
}

- (void)processNodes:(PrimitiveGroup *)group
         stringTable:(NSArray *)stringTable
           latOffset:(double)latOffset
           lonOffset:(double)lonOffset
         granularity:(double)granularity
     dateGranularity:(double)dateGranularity
{
    for (Node *node in [group nodesList])
    {
        Info *info = [node info];
        OSPNode *ospNode = [[OSPNode alloc] init];
        
        NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithCapacity:[[node valsList] count]];
        PSYMultiEnumerator(@[[node valsList], [node keysList]], NO, ^ (__unsafe_unretained id const *objects, BOOL *stop)
                           {
                               [tags setValue:stringTable[[objects[0] unsignedLongValue]]
                                       forKey:stringTable[[objects[1] unsignedLongValue]]];
                           });
		
        [ospNode setLocation:CLLocationCoordinate2DMake([node lat] * granularity + latOffset, [node lon] * granularity + lonOffset)];
        [ospNode setIdentity:[node id]];
        [ospNode setTags:tags];
        [ospNode setTimestamp:[NSDate dateWithTimeIntervalSince1970:[info timestamp] * dateGranularity]];
        [ospNode setChangesetId:[info changeset]];
        [ospNode setUserId:[info uid]];
        [ospNode setUser:stringTable[[info userSid]]];
        [ospNode setVisible:[info visible]];
        [ospNode setVersion:[info version]];
        
        [[self delegate] parser:self didFindAPIObject:ospNode];
    }
}

- (void)processDenseNodes:(PrimitiveGroup *)group
              stringTable:(NSArray *)stringTable
                latOffset:(double)latOffset
                lonOffset:(double)lonOffset
              granularity:(double)granularity
          dateGranularity:(double)dateGranularity
{
    __block NSUInteger l = 0;
    __block int64_t deltaId = 0;
    __block int64_t deltaLat = 0;
    __block int64_t deltaLon = 0;
    __block int32_t deltaVersion = 0;
    __block int32_t deltaTimestamp = 0;
    __block int64_t deltaChangeset = 0;
    __block int32_t deltaUserId = 0;
    __block int32_t deltaUserStringId = 0;
	
    DenseNodes *dense = [group dense];
    DenseInfo *denseInfo = [dense denseinfo];
    BOOL hasVisible = [denseInfo visibleList] != nil;
    PSYMultiEnumerator([NSArray arrayWithObjects:
                        [dense idList],
                        [dense latList],
                        [dense lonList],
                        [denseInfo versionList],
                        [denseInfo timestampList],
                        [denseInfo changesetList],
                        [denseInfo uidList],
                        [denseInfo userSidList],
                        [denseInfo visibleList],
                        nil], NO, ^ (__unsafe_unretained id const *objects, BOOL *stop)
                       {
                           deltaId += [objects[0] longLongValue];
                           deltaLat += [objects[1] longLongValue];
                           deltaLon += [objects[2] longLongValue];
                           deltaVersion += [objects[3] longValue];
                           deltaTimestamp += [objects[4] longValue];
                           deltaChangeset += [objects[5] longLongValue];
                           deltaUserId += [objects[6] longValue];
                           deltaUserStringId += [objects[7] longValue];
                           
                           NSMutableDictionary *tags = [NSMutableDictionary dictionary];
                           
                           NSUInteger maxKeyValue = [[dense keysValsList] count];
                           if (l < maxKeyValue)
                           {
                               while ([dense keysValsAtIndex:l] != 0 && l < maxKeyValue)
                               {
                                   [tags setValue:stringTable[[dense keysValsAtIndex:l+1]] forKey:stringTable[[dense keysValsAtIndex:l]]];
                                   l += 2;
                               }
                               l++; // Used to skip over the 0 id string between key value sets.
                           }
                           
                           double lat = latOffset + (deltaLat * granularity);
                           double lon = lonOffset + (deltaLon * granularity);
                           NSTimeInterval timestamp = deltaTimestamp * dateGranularity;
                           
                           OSPNode *node = [[OSPNode alloc] init];
                           [node setLocation:CLLocationCoordinate2DMake(lat, lon)];
                           [node setIdentity:deltaId];
                           [node setTags:tags];
                           [node setTimestamp:[NSDate dateWithTimeIntervalSince1970:timestamp]];
                           [node setChangesetId:deltaChangeset];
                           [node setUser:stringTable[deltaUserStringId]];
                           [node setUserId:deltaUserId];
                           [node setVisible:hasVisible ? [objects[8] boolValue] : YES];
                           [node setVersion:deltaVersion];
                           
                           [[self delegate] parser:self didFindAPIObject:node];
                       });
}

- (void)processWays:(PrimitiveGroup *)group
        stringTable:(NSArray *)stringTable
    dateGranularity:(double)dateGranularity
{
    for (Way *way in [group waysList])
    {
        Info *info = [way info];
        OSPWay *ospWay = [[OSPWay alloc] init];
        
        int64_t deltaRef = 0;
        for (NSNumber *ref in [way refsList])
        {
            deltaRef += [ref longLongValue];
            [ospWay addNodeWithId:deltaRef];
        }
		
        NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithCapacity:[[way valsList] count]];
        PSYMultiEnumerator([NSArray arrayWithObjects:[way valsList], [way keysList], nil], NO, ^ (__unsafe_unretained id const *objects, BOOL *stop)
                           {
                               [tags setValue:stringTable[[objects[0] unsignedLongValue]]
                                       forKey:stringTable[[objects[1] unsignedLongValue]]];
                           });
		
        [ospWay setIdentity:[way id]];
        [ospWay setTags:tags];
        [ospWay setTimestamp:[NSDate dateWithTimeIntervalSince1970:[info timestamp] * dateGranularity]];
        [ospWay setChangesetId:[info changeset]];
        [ospWay setUserId:[info uid]];
        [ospWay setUser:stringTable[[info userSid]]];
        [ospWay setVisible:[info visible]];
        [ospWay setVersion:[info version]];
        
        [[self delegate] parser:self didFindAPIObject:ospWay];
    }
}

- (void)processRelations:(PrimitiveGroup *)group
             stringTable:(NSArray *)stringTable
         dateGranularity:(double)dateGranularity
{
    for (Relation *relation in [group relationsList])
    {
        Info *info = [relation info];
        OSPRelation *ospRelation = [[OSPRelation alloc] init];
        
        NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithCapacity:[[relation valsList] count]];
        PSYMultiEnumerator(@[[relation valsList], [relation keysList]], NO, ^ (__unsafe_unretained id const *objects, BOOL *stop)
                           {
                               [tags setValue:stringTable[[objects[0] unsignedLongValue]]
                                       forKey:stringTable[[objects[1] unsignedLongValue]]];
                           });
        __block int64_t deltaMemberId = 0;
        NSMutableArray *members = [NSMutableArray arrayWithCapacity:[[relation rolesSidList] count]];
        PSYMultiEnumerator(@[[relation rolesSidList], [relation memidsList], [relation typesList]], NO, ^ (__unsafe_unretained id const *objects, BOOL *stop)
                           {
                               deltaMemberId += [objects[1] longLongValue];
                               [members addObject:[[OSPMember alloc] initWithType:OSPMemberTypeFromRelation_MemberType([objects[2] intValue])
                                                               referencedObjectId:deltaMemberId
                                                                             role:stringTable[[objects[0] longValue]]]];
                           });
        
        [ospRelation setIdentity:[relation id]];
        [ospRelation setTags:tags];
        [ospRelation setTimestamp:[NSDate dateWithTimeIntervalSince1970:[info timestamp] * dateGranularity]];
        [ospRelation setChangesetId:[info changeset]];
        [ospRelation setUserId:[info uid]];
        [ospRelation setUser:stringTable[[info userSid]]];
        [ospRelation setVisible:[info visible]];
        [ospRelation setVersion:[info version]];
        
        [[self delegate] parser:self didFindAPIObject:ospRelation];
    }
}

@end
