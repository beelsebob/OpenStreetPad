//
//  NSString+XMLEscaping.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 04/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "NSString+XMLEscaping.h"

@implementation NSString (XMLEscaping)

- (id)stringByAddingXMLEscaping
{
    NSUInteger len = [self length];
    NSMutableString *newString = [NSMutableString stringWithCapacity:len];
    unichar chars[255];
    NSUInteger consumedLength = 0;
    NSUInteger characterIndexAfterLastEscapedChar = 0;
    NSUInteger numberOfUnescapedChars = 0;
    
    do
    {
        char charsToConsume = len < consumedLength + 255 ? len - consumedLength : 255;
        [self getCharacters:chars range:NSMakeRange(consumedLength, charsToConsume)];
        
        for (char charNum = 0; charNum < charsToConsume; charNum++)
        {
            unichar c = chars[charNum];
            if (c <= 0xd7ff)
            {
                if (c >= 0x20 || c == '\n' || c == '\r' || c == '\t')
                {
                    switch (c)
                    {
                        case '"':
                            [newString appendString:[self substringWithRange:NSMakeRange(characterIndexAfterLastEscapedChar, numberOfUnescapedChars)]];
                            [newString appendString:@"&quot;"];
                            characterIndexAfterLastEscapedChar = consumedLength + charNum + 1;
                            numberOfUnescapedChars = 0;
                            break;
                        case '<':
                            [newString appendString:[self substringWithRange:NSMakeRange(characterIndexAfterLastEscapedChar, numberOfUnescapedChars)]];
                            [newString appendString:@"&lt;"];
                            characterIndexAfterLastEscapedChar = consumedLength + charNum + 1;
                            numberOfUnescapedChars = 0;
                            break;
                        case '>':
                            [newString appendString:[self substringWithRange:NSMakeRange(characterIndexAfterLastEscapedChar, numberOfUnescapedChars)]];
                            [newString appendString:@"&gt;"];
                            characterIndexAfterLastEscapedChar = consumedLength + charNum + 1;
                            numberOfUnescapedChars = 0;
                            break;
                        case '&':
                            [newString appendString:[self substringWithRange:NSMakeRange(characterIndexAfterLastEscapedChar, numberOfUnescapedChars)]];
                            [newString appendString:@"&amp;"];
                            characterIndexAfterLastEscapedChar = consumedLength + charNum + 1;
                            numberOfUnescapedChars = 0;
                            break;
                        default:
                            numberOfUnescapedChars++;
                            break;
                    }
                }
            }
            else if (c < 0xe000 || c > 0xfffd)
            {
                [newString appendString:[self substringWithRange:NSMakeRange(characterIndexAfterLastEscapedChar, numberOfUnescapedChars)]];
                characterIndexAfterLastEscapedChar = consumedLength + charNum + 1;
                numberOfUnescapedChars = 0;
            }
            else
            {
                numberOfUnescapedChars++;
            }
        }
        consumedLength += charsToConsume;
    }
    while (consumedLength < len);
    
    [newString appendString:[self substringWithRange:NSMakeRange(characterIndexAfterLastEscapedChar, numberOfUnescapedChars)]];
    
    return [newString copy];
}

@end
