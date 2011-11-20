//
//  NamedSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPMapCSSSpecifier.h"

@interface OSPMapCSSNamedSpecifier : OSPMapCSSSpecifier

@property (readwrite, copy) NSString *name;

@end
