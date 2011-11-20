//
//  Test.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPAPIObject.h"

#import "CoreParse.h"

@interface OSPMapCSSTest : NSObject <CPParseResult>

- (BOOL)matchesObject:(OSPAPIObject *)object;

@end
