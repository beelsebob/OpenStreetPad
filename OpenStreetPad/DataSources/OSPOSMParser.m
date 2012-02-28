//
//  OSPOSMParser.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "OSPOSMParser.h"

#import "OSPNode.h"
#import "OSPWay.h"
#import "OSPRelation.h"
#import "OSPMember.h"

@interface OSPOSMParser () <NSXMLParserDelegate>

@property (readwrite, strong) NSXMLParser *xmlParser;

@property (readwrite, strong) NSMutableDictionary *currentObjectTags;
@property (readwrite, strong) OSPAPIObject *currentObject;

- (void)setupAPIObject:(OSPAPIObject *)object withAttributes:(NSDictionary *)attributes;

@end

@implementation OSPOSMParser

@synthesize delegate;

@synthesize xmlParser;

@synthesize currentObject;
@synthesize currentObjectTags;

- (id)initWithStream:(NSInputStream *)stream
{
    self = [super init];
    
    if (nil != self)
    {
        [self setXmlParser:[[NSXMLParser alloc] initWithStream:stream]];
        [[self xmlParser] setDelegate:self];
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
            [[self delegate] parser:self didFindAPIObject:[self currentObject]];
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
    [[self delegate] parserDidEndDocument:self];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [[self delegate] parser:self didFailWithError:parseError];
}

@end
