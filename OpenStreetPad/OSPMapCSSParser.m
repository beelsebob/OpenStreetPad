//
//  OSPMapCSSParser.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 29/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSParser.h"

#import "CoreParse.h"

@interface OSPMapCSSParser () <CPTokeniserDelegate, CPParserDelegate>

@property (readwrite, strong) CPTokeniser *tokeniser;
@property (readwrite, strong) CPParser *parser;

@end

@implementation OSPMapCSSParser
{
    NSCharacterSet *symbolsSet;
    int nestingDepth;
    BOOL inTest;
    BOOL inStyle;
    BOOL justTokenisedObject;
    BOOL justTokenisedDoubleColon;
    BOOL inRange;
}

@synthesize tokeniser;
@synthesize parser;

- (id)init
{
    self = [super init];
    
    if (nil != self)
    {
        symbolsSet = [NSCharacterSet characterSetWithCharactersInString:@"*[]{}().,;@|-!=<>:!#%"];
        
        NSDictionary *pt = [NSKeyedUnarchiver unarchiveObjectWithFile:[[NSBundle mainBundle] pathForResource:@"parser" ofType:@"osp"]];
        [self setTokeniser:[pt objectForKey:@"tokeniser"]];
        [self setParser:[pt objectForKey:@"parser"]];
        [[self tokeniser] setDelegate:self];
        [[self parser] setDelegate:self];
    }
    
    return self;
}

- (OSPMapCSSStyleSheet *)parse:(NSString *)mapCSS
{
    CPTokenStream *stream = [[CPTokenStream alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^()
                   {
                       @autoreleasepool
                       {
                           [[self tokeniser] tokenise:mapCSS into:stream];
                       }
                   });
    return [[OSPMapCSSStyleSheet alloc] initWithRules:[[self parser] parse:stream]];
}

- (BOOL)tokeniser:(CPTokeniser *)tokeniser shouldConsumeToken:(CPToken *)token
{
    NSString *name = [token name];
    if ([name isEqualToString:@"["])
    {
        inTest = YES;
    }
    else if ([name isEqualToString:@"]"])
    {
        inTest = NO;
    }
    else if ([name isEqualToString:@","])
    {
        inTest = NO;
        inStyle = NO;
    }
    else if ([name isEqualToString:@":"])
    {
        inStyle = !inTest;
    }
    else if ([name isEqualToString:@";"] || [name isEqualToString:@"}"])
    {
        inStyle = NO;
    }
    else if ([name isEqualToString:@"|z"])
    {
        inRange = YES;
    }
    else if (inRange && [token isKindOfClass:[CPNumberToken class]])
    {
        return [[(CPNumberToken *)token number] floatValue] >= 0;
    }
    else
    {
        if (inRange && ![name isEqualToString:@"-"])
        {
            inRange = NO;
        }
        
        if ([token isKindOfClass:[CPKeywordToken class]])
        {
            return (!(inStyle || inTest) || 
                    [symbolsSet characterIsMember:[name characterAtIndex:0]] ||
                    [name isEqualToString:@"eval"] ||
                    [name isEqualToString:@"tag"]  ||
                    [name isEqualToString:@"url"]  ||
                    [name isEqualToString:@"set"]  ||
                    [name isEqualToString:@"pt"]   ||
                    [name isEqualToString:@"px"]   ||
                    [name isEqualToString:@"rgb"]  ||
                    [name isEqualToString:@"rgba"]);
        }
    }
    
    return YES;
}

- (NSArray *)tokeniser:(CPTokeniser *)tokeniser willProduceToken:(CPToken *)token
{
    NSString *name = [token name];
    
    if ([token isKindOfClass:[CPWhiteSpaceToken class]])
    {
        if (justTokenisedObject)
        {
            return [NSArray arrayWithObject:token];
        }
        else
        {
            return [NSArray array];
        }
    }
    
    justTokenisedObject = NO;
    if ([name isEqualToString:@"Comment"])
    {
        return [NSArray array];
    }
        
    if ([name isEqualToString:@"node"] || [name isEqualToString:@"way" ] || [name isEqualToString:@"relation"] ||
        [name isEqualToString:@"area"] || [name isEqualToString:@"line"] || [name isEqualToString:@"canvas"] || ([name isEqualToString:@"*"] && !justTokenisedDoubleColon))
    {
        justTokenisedObject = YES;
    }
    
    justTokenisedDoubleColon = NO;
    if ([name isEqualToString:@"::"])
    {
        justTokenisedDoubleColon = YES;
    }
    
    return [NSArray arrayWithObject:token];
}

- (NSUInteger)tokeniser:(CPTokeniser *)tokeniser didNotFindTokenOnInput:(NSString *)input position:(NSUInteger)position error:(NSString *__autoreleasing *)errorMessage
{
    NSLog(@"Argh");
    return 1;
}

- (CPRecoveryAction *)parser:(CPParser *)parser didEncounterErrorOnInput:(CPTokenStream *)inputStream expecting:(NSSet *)acceptableTokens
{
    CPToken *t = [inputStream peekToken];
    if ([t isEqual:[CPKeywordToken tokenWithKeyword:@"}"]] &&
        [acceptableTokens containsObject:@";"])
    {
        return [CPRecoveryAction recoveryActionWithAdditionalToken:[CPKeywordToken tokenWithKeyword:@";"]];
    }
    if ([t isEqual:[CPKeywordToken tokenWithKeyword:@"{"]] &&
        [acceptableTokens containsObject:@","])
    {
        return [CPRecoveryAction recoveryActionWithAdditionalToken:[CPKeywordToken tokenWithKeyword:@","]];
    }
    
    NSLog(@"%ld:%ld: parse error.  Expected %@, found %@", (long)[t lineNumber] + 1, (long)[t columnNumber] + 1, acceptableTokens, t);
    return [CPRecoveryAction recoveryActionStop];
}

@end
