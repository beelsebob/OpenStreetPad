//
//  SizeListSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSpecifier.h"

#import "OSPMapCSSSize.h"

@interface OSPMapCSSSizeListSpecifier : OSPMapCSSSpecifier

@property (readwrite, copy) NSArray *sizes;

- (id)initWithSize:(OSPMapCSSSize *)size;

@end
