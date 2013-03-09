//
//  OSPOpenStreetMapXMLParser.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOpenStreetMapXMLParser.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"

@interface OSPOpenStreetMapXMLParser () <NSXMLParserDelegate>

@property (readwrite, strong) NSXMLParser *xmlParser;

@property (readwrite, strong) NSMutableDictionary *currentObjectTags;
@property (readwrite, strong) OSPAPIObject *currentObject;
@property (readwrite, strong) NSDateFormatter *dateFormatter;

- (void)setupAPIObject:(OSPAPIObject *)object withAttributes:(NSDictionary *)attributes;

@end

@implementation OSPOpenStreetMapXMLParser

@synthesize xmlParser;

@synthesize currentObject;
@synthesize currentObjectTags;
@synthesize dateFormatter;

- (id)initWithStream:(NSInputStream *)stream
{
    self = [super initWithStream:stream];
    
    if (nil != self)
    {
        [self setXmlParser:[[NSXMLParser alloc] initWithStream:stream]];
        [[self xmlParser] setDelegate:self];
        [self setDateFormatter:[[NSDateFormatter alloc] init]];
        [[self dateFormatter] setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [[self dateFormatter] setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [[self dateFormatter] setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    return self;
}

- (void)parse
{
    [[self xmlParser] parse];
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
            [self currentObjectTags][attributeDict[@"k"]] = attributeDict[@"v"];
        }
        else if ([elementName isEqualToString:@"node"])
        {
            OSPNode *node = [[OSPNode alloc] init];
            
            [self setCurrentObject:node];
            [self setCurrentObjectTags:[NSMutableDictionary dictionary]];
            [self setupAPIObject:node withAttributes:attributeDict];
            [node setLocation:CLLocationCoordinate2DMake([attributeDict[@"lat"] doubleValue], [attributeDict[@"lon"] doubleValue])];
        }
        else if ([elementName isEqualToString:@"nd"])
        {
            [(OSPWay *)[self currentObject] addNodeWithId:[attributeDict[@"ref"] integerValue]];
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
            NSString *typeString = attributeDict[@"type"];
            OSPMemberType t = [typeString isEqualToString:@"node"] ? OSPMemberTypeNode : [typeString isEqualToString:@"way"] ? OSPMemberTypeWay : OSPMemberTypeRelation;
            [(OSPRelation *)[self currentObject] addMember:[OSPMember memberWithType:t referencedObjectId:[attributeDict[@"ref"] integerValue] role:attributeDict[@"role"]]];
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
            [[self delegate] parser:self didFindAPIObject:[self currentObject]];
            [self setCurrentObject:nil];
        }
    }
}

- (void)setupAPIObject:(OSPAPIObject *)object withAttributes:(NSDictionary *)attributes
{
    [object setChangesetId:[attributes[@"changeset"] integerValue]];
    [object setIdentity:[attributes[@"id"] integerValue]];
    [object setUserId:[attributes[@"uid"] integerValue]];
    [object setUser:attributes[@"user"]];
    [object setVersion:[attributes[@"version"] integerValue]];
    [object setVisible:[attributes[@"visible"] boolValue]];
    [object setTimestamp:[[self dateFormatter] dateFromString:attributes[@"timestamp"]]];
}

- (void)parserDidEndDocument:(NSXMLParser *)p
{
    [[self delegate] parserDidEndDocument:self];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [[self delegate] parser:self didFailWithError:parseError];
}

@end
