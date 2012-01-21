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
            NSCharacterSet *identifierCharacters = [NSCharacterSet characterSetWithCharactersInString:
                                                    @"abcdefghijklmnopqrstuvwxyz"
                                                    @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                                    @"0123456789-_"];
            NSCharacterSet *initialIdCharacters = [NSCharacterSet characterSetWithCharactersInString:
                                                   @"abcdefghijklmnopqrstuvwxyz"
                                                   @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                                   @"_-"];
            CPTokeniser *mapCssTokeniser = [[CPTokeniser alloc] init];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"node"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"way"      invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"relation" invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"area"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"line"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"canvas"   invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"url"      invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"eval"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"rgba"     invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"rgb"      invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"pt"       invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"px"       invalidFollowingCharacters:identifierCharacters]];
            [mapCssTokeniser addTokenRecogniser:[OSPMapCSSHashColourRecogniser hashColourRecogniser]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"*"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"["]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"]"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"{"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"}"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"("]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@")"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"."]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@","]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@";"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"@import"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"|z"]];
            [mapCssTokeniser addTokenRecogniser:[CPNumberRecogniser numberRecogniser]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"-"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"!="]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"=~"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"<"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@">"]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"<="]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@">="]];
            [mapCssTokeniser addTokenRecogniser:[CPKeywordRecogniser recogniserForKeyword:@"="]];
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
                                  @"OSPMapCSSRuleset       ::= <OSPMapCSSRule>*;"
                                  @"OSPMapCSSRule          ::= <OSPMapCSSSelector> <OSPMapCSSCommaSelector>* <OSPMapCSSDeclaration>+ | <OSPMapCSSImport>;"
                                  @"OSPMapCSSImport        ::= \"@import\" \"url\" \"(\" \"String\" \")\" \"Identifier\";"
                                  @"OSPMapCSSCommaSelector ::= \",\" <OSPMapCSSSelector>;"
                                  @"OSPMapCSSSelector      ::= <OSPMapCSSSubselector>+;"
                                  @"OSPMapCSSSubselector   ::= <OSPMapCSSObject> \"Whitespace\" | <OSPMapCSSObject> <OSPMapCSSZoom> <OSPMapCSSTest>* | <OSPMapCSSObject> <OSPMapCSSTest>* | <OSPMapCSSObject> \"Whitespace\" <OSPMapCSSClass>;"
                                  @"OSPMapCSSZoom          ::= \"|z\" <range>;"
                                  @"range                  ::= \"Number\" | \"Number\" \"-\" \"Number\";"
                                  @"OSPMapCSSTest          ::= \"[\" <condition> \"]\";"
                                  @"condition              ::= <OSPMapCSSTag> <binary> <value> | <unary> <OSPMapCSSTag> | <OSPMapCSSTag>;"
                                  @"OSPMapCSSTag           ::= <OSPMapCSSKey> (\":\" <OSPMapCSSKey>)*;"
                                  @"OSPMapCSSKey           ::= \"Identifier\";"
                                  @"value                  ::= \"String\" | \"Regex\";"
                                  @"binary                 ::= \"=\" | \"!=\" | \"=~\" | \"<\" | \">\" | \"<=\" | \">=\";"
                                  @"unary                  ::= \"-\" | \"!\";"
                                  @"OSPMapCSSClass         ::= <class> | \"!\" <class>;"
                                  @"class                  ::= \".\" \"Identifier\";"
                                  @"OSPMapCSSObject        ::= \"node\" | \"way\" | \"relation\" | \"area\" | \"line\" | \"canvas\" | \"*\";"
                                  @"OSPMapCSSDeclaration   ::= \"{\" <OSPMapCSSStyle>+ \"}\" | \"{\" \"}\";"
                                  @"OSPMapCSSStyle         ::= <Styledef> \";\";"
                                  @"Styledef               ::= <OSPMapCSSKey> \":\" <OSPMapCSSSpecifier>;"
                                  @"OSPMapCSSSpecifier     ::= <OSPMapCSSNamed> | <OSPMapCSSSize> <OSPMapCSSCommaSize>* | <OSPMapCSSColour> | <OSPMapCSSUrl> | <OSPMapCSSEval>;"
                                  @"OSPMapCSSNamed         ::= \"Identifier\";"
                                  @"OSPMapCSSSize          ::= \"Number\" <Unit>;"
                                  @"Unit                   ::= \"pt\" | \"px\" | \"%\" | ;"
                                  @"OSPMapCSSCommaSize     ::= \",\" <OSPMapCSSSize>;"
                                  @"OSPMapCSSColour        ::= \"HashColour\" | \"rgb\" \"(\" \"Number\" \",\" \"Number\" \",\" \"Number\" \")\" | \"rgba\" \"(\" \"Number\" \",\" \"Number\" \",\" \"Number\"  \",\" \"Number\" \")\";"
                                  @"OSPMapCSSUrl           ::= \"url\" \"(\" <UrlContent> \")\";"
                                  @"UrlContent             ::= \"String\" | <OSPMapCSSEval>;"
                                  @"OSPMapCSSEval          ::= \"eval\" \"(\" \"String\" \")\";"];
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

