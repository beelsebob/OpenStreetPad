//
//  OSPMapCSSStyleSheet.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 05/11/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Ruleset.h"

#import "OSPAPIObject.h"

@interface OSPMapCSSStyleSheet : NSObject

@property (readwrite, strong) Ruleset *ruleset;

- (id)initWithRules:(Ruleset *)ruleset;

- (NSDictionary *)stylesForObject:(OSPAPIObject *)apiObject;

@end
