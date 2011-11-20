//
//  URLSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "OSPMapCSSSpecifier.h"

#import "OSPMapCSSUrl.h"

@interface OSPMapCSSURLSpecifier : OSPMapCSSSpecifier

@property (readwrite, retain) OSPMapCSSUrl *url;

@end
