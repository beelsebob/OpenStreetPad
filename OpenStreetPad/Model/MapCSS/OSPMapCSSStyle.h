//
//  Style.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"
#import "OSPMapCSSSpecifierList.h"

@interface OSPMapCSSStyle : NSObject <CPParseResult>

@property (readwrite, assign, getter = isExit) BOOL exit;
@property (readwrite, copy) NSString *key;
@property (readwrite, retain) OSPMapCSSSpecifierList *specifiers;

@end
