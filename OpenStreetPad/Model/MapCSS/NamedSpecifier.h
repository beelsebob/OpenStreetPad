//
//  NamedSpecifier.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Specifier.h"

@interface NamedSpecifier : Specifier

@property (readwrite, copy) NSString *name;

@end
