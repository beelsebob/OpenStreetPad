//
//  OSPMapCSSSpecifierList.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 06/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

@interface OSPMapCSSSpecifierList : NSObject <CPParseResult>

@property (readwrite, strong) NSArray *specifiers;

@end
