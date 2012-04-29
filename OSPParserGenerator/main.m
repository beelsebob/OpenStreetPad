//
//  main.m
//  OSPParserGenerator
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreParse/CoreParse.h>

#import "OSPMapCSSHashColourRecogniser.h"

int main (int argc, const char * argv[])
{
    @autoreleasepool
    {
        if (argc >= 2)
        {
            NSMutableCharacterSet *identifierCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
            [identifierCharacters addCharactersInString:@"-_"];
            NSMutableCharacterSet *initialIdCharacters = [NSMutableCharacterSet letterCharacterSet];
            [initialIdCharacters addCharactersInString:@"-_"];
            CPTokeniser *mapCssTokeniser = [[CPTokeniser alloc] init];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"node"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"way"      invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"relation" invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"area"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"line"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"canvas"   invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"meta"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"url"      invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"eval"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"tag"      invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"rgba"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"rgb"      invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"pt"       invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"px"       invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"exit"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[OSPMapCSSHashColourRecogniser hashColourRecogniser]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"*"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"["]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"]"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"{"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"}"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"("]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@")"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@","]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@";"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"@import"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"|z"]];
            [mapCssTokeniser addTokenRecogniser:[CPNumberRecogniser numberRecogniser]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"."]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"-" invalidFollowingCharacters:initialIdCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"!="]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"=~"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"<="]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@">="]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"<"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@">"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"="]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"::"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@":"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"!"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"#"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"%"]];
            [mapCssTokeniser addTokenRecogniser:[CPWhiteSpaceRecogniser whiteSpaceRecogniser]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"/*" endQuote:@"*/" name:@"Comment"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"//" endQuote:@"\n" name:@"Comment"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"/"  endQuote:@"/"  escapeSequence:@"\\" name:@"Regex"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"'"  endQuote:@"'"  escapeSequence:@"\\" name:@"String"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"\"" endQuote:@"\"" escapeSequence:@"\\" name:@"String"]];
            [mapCssTokeniser addTokenRecogniser:[CPIdentifierRecogniser identifierRecogniserWithInitialCharacters:initialIdCharacters identifierCharacters:identifierCharacters]];
            
            CPGrammar *grammar = [CPGrammar grammarWithStart:@"OSPMapCSSRuleset"
                                              backusNaurForm:
                                  @"OSPMapCSSRuleset         ::= <OSPMapCSSRule>*;"
                                  @"OSPMapCSSRule            ::= (<OSPMapCSSSelector> ',')+ <OSPMapCSSDeclaration>+ | <OSPMapCSSImport>;"
                                  @"OSPMapCSSImport          ::= '@import' 'url' '(' 'String' ')' 'Identifier';"
                                  @"OSPMapCSSSelector        ::= (<OSPMapCSSSubselector> '>'?)+ <OSPMapCSSLayerIdentifier>?;"
                                  @"OSPMapCSSLayerIdentifier ::= '::' 'Identifier';"
                                  @"OSPMapCSSSubselector     ::= <OSPMapCSSObject> 'Whitespace' | <OSPMapCSSObject> <OSPMapCSSZoom>? <OSPMapCSSTest>* <OSPMapCSSClass>*;"
                                  @"OSPMapCSSZoom            ::= '|z' <range>;"
                                  @"range                    ::= 'Number' | 'Number' '-' 'Number' | 'Number' '-' | '-' 'Number';"
                                  @"OSPMapCSSTest            ::= '[' <condition> ']';"
                                  @"condition                ::= <OSPMapCSSTag> <binary> <value> | <unary> <OSPMapCSSTag> | <OSPMapCSSTag>;"
                                  @"OSPMapCSSTag             ::= 'String' | <OSPMapCSSKey>? (':' <OSPMapCSSKey>)*;"
                                  @"OSPMapCSSKey             ::= 'Identifier';"
                                  @"value                    ::= 'Identifier' | 'Number' | 'String' | 'Regex';"
                                  @"binary                   ::= '=' | '!=' | '=~' | '<' | '>' | '<=' | '>=';"
                                  @"unary                    ::= '-' | '!';"
                                  @"OSPMapCSSClass           ::= <pseudoclass> | '!' <pseudoclass>;"
                                  @"pseudoclass              ::= ':' 'Identifier';"
                                  @"OSPMapCSSObject          ::= 'node' | 'way' | 'relation' | 'area' | 'line' | 'canvas' | 'meta' | '*';"
                                  @"OSPMapCSSDeclaration     ::= '{' <OSPMapCSSStyle>* '}';"
                                  @"OSPMapCSSStyle           ::= <Styledef> ';' | <OSPMapCSSRule>;"
                                  @"Styledef                 ::= <OSPMapCSSKey> ':' <OSPMapCSSSpecifierList> | 'exit';"
                                  @"OSPMapCSSSpecifierList   ::= <OSPMapCSSSpecifier> <OSPMapCSSCommaSpecifier>*;"
                                  @"OSPMapCSSCommaSpecifier  ::= ',' <OSPMapCSSSpecifier>;"
                                  @"OSPMapCSSSpecifier       ::= <OSPMapCSSNamed> | <OSPMapCSSSize> | <OSPMapCSSColour> | <OSPMapCSSUrl> | <OSPMapCSSEval> | <OSPMapCSSTagSpec>;"
                                  @"OSPMapCSSNamed           ::= 'Identifier';"
                                  @"OSPMapCSSSize            ::= 'Number' <Unit>;"
                                  @"Unit                     ::= 'pt' | 'px' | '%' | ;"
                                  @"OSPMapCSSCommaSize       ::= ',' <OSPMapCSSSize>;"
                                  @"OSPMapCSSColour          ::= 'HashColour' | 'rgb' '(' 'Number' ',' 'Number' ',' 'Number' ')' | 'rgba' '(' 'Number' ',' 'Number' ',' 'Number'  ',' 'Number' ')';"
                                  @"OSPMapCSSUrl             ::= 'url' '(' 'String' ')' | 'String';"
                                  @"OSPMapCSSEval            ::= 'eval' '(' 'String' ')';"
                                  @"OSPMapCSSTagSpec         ::= 'tag' '(' 'String' ')';"];
            CPParser *mapCssParser = [[CPLALR1Parser alloc] initWithGrammar:grammar];
            
            if (nil == mapCssParser)
            {
                NSLog(@"Parser could not be constructed");
            }
            else
            {
                [NSKeyedArchiver archiveRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    mapCssTokeniser, @"tokeniser",
                                                    mapCssParser   , @"parser",
                                                    nil]
                                            toFile:[[NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding] stringByExpandingTildeInPath]];
            }
        }
        else
        {
            NSLog(@"Usage: OSPParserGenerator <output path>");
        }
    }
    return 0;
}

