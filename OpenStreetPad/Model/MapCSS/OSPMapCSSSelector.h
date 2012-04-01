//
//  OSPMapCSSSelector.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 01/04/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

#import "OSPAPIObject.h"

@interface OSPMapCSSSelector : NSObject <CPParseResult>

@property (readwrite, strong) NSArray *subselectors;
@property (readwrite, strong) NSString *layerIdentifier;

- (BOOL)matchesObject:(OSPAPIObject *)object atZoom:(float)zoom;

@end
