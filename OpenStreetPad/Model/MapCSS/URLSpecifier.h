//
//  URLSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import "Specifier.h"

#import "Url.h"

@interface URLSpecifier : Specifier

@property (readwrite, retain) Url *url;

@end
