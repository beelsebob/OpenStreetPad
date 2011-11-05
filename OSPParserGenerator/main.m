//
//  main.m
//  OSPParserGenerator
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Hunted Cow Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreParse/CoreParse.h>

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
            [mapCssTokeniser addTokenRecogniser:[CPNumberRecogniser numberRecogniser]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"/*" endQuote:@"*/" name:@"Comment"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"//" endQuote:@"\n" name:@"Comment"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"/"  endQuote:@"/"  escapeSequence:@"\\" name:@"Regex"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"'"  endQuote:@"'"  escapeSequence:@"\\" name:@"String"]];
            [mapCssTokeniser addTokenRecogniser:[CPQuotedRecogniser quotedRecogniserWithStartQuote:@"\"" endQuote:@"\"" escapeSequence:@"\\" name:@"String"]];
            [mapCssTokeniser addTokenRecogniser:[CPIdentifierRecogniser identifierRecogniserWithInitialCharacters:initialIdCharacters identifierCharacters:identifierCharacters]];
            
            CPGrammar *grammar = [CPGrammar grammarWithStart:@"Ruleset"
                                              backusNaurForm:
                                  @"Ruleset         ::= <Rule>*;"
                                  @"Rule            ::= <Selector> <CommaSelector>* <Declaration>+ | <Import>;"
                                  @"Import          ::= \"@import\" \"url\" \"(\" \"String\" \")\" \"Identifier\";"
                                  @"CommaSelector   ::= \",\" <Selector>;"
                                  @"Selector        ::= <Subselector>+;"
                                  @"Subselector     ::= <OSPMapCSSObject> \"Whitespace\" | <OSPMapCSSObject> <Zoom> <Test>* | <OSPMapCSSObject> <Test>* | <OSPMapCSSObject> \"Whitespace\" <OSPMapCSSClass>;"
                                  @"Zoom            ::= \"|z\" <range>;"
                                  @"range           ::= \"Number\" | \"Number\" \"-\" \"Number\";"
                                  @"Test            ::= \"[\" <condition> \"]\";"
                                  @"condition       ::= <Tag> <binary> <value> | <unary> <Tag> | <Tag>;"
                                  @"Tag             ::= <Key> (\":\" <Key>)*;"
                                  @"Key             ::= \"Identifier\";"
                                  @"value           ::= \"String\" | \"Regex\";"
                                  @"binary          ::= \"=\" | \"!=\" | \"=~\" | \"<\" | \">\" | \"<=\" | \">=\";"
                                  @"unary           ::= \"-\" | \"!\";"
                                  @"OSPMapCSSClass  ::= <class> | \"!\" <class>;"
                                  @"class           ::= \".\" \"Identifier\";"
                                  @"OSPMapCSSObject ::= \"node\" | \"way\" | \"relation\" | \"area\" | \"line\" | \"canvas\" | \"*\";"
                                  @"Declaration     ::= \"{\" <OSPMapCSSStyle>+ \"}\" | \"{\" \"}\";"
                                  @"OSPMapCSSStyle  ::= <Styledef> \";\";"
                                  @"Styledef        ::= <Key> \":\" <Specifier>;"
                                  @"Specifier       ::= <Named> | <MapCSSSize> <CommaSize>* | <Colour> | <Url> | <Eval>;"
                                  @"Named           ::= \"Identifier\";"
                                  @"MapCSSSize      ::= \"Number\" <Unit>;"
                                  @"Unit            ::= \"pt\" | \"px\" | \"%\" | ;"
                                  @"CommaSize       ::= \",\" <MapCSSSize>;"
                                  @"Colour          ::= \"HashColour\" | \"rgb\" \"(\" \"Number\" \",\" \"Number\" \",\" \"Number\" \")\" | \"rgba\" \"(\" \"Number\" \",\" \"Number\" \",\" \"Number\"  \",\" \"Number\" \")\";"
                                  @"Url             ::= \"url\" \"(\" <UrlContent> \")\";"
                                  @"UrlContent      ::= \"String\" | <Eval>;"
                                  @"Eval            ::= \"eval\" \"(\" \"String\" \")\";"];
            CPParser *mapCssParser = [[CPLALR1Parser alloc] initWithGrammar:grammar];
            
            [NSKeyedArchiver archiveRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                mapCssTokeniser, @"tokeniser",
                                                mapCssParser   , @"parser",
                                                nil]
                                        toFile:[[NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding] stringByExpandingTildeInPath]];
        }
        else
        {
            NSLog(@"Usage: OSPParserGenerator <output path>");
        }
    }
    return 0;
}

