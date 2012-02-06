//
//  Url.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 31/10/2011.
//  Copyright (c) 2011 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreParse.h"

@interface OSPMapCSSUrl : NSObject <CPParseResult>

@property (readwrite, strong) NSURL *content;

- (id)initWithURL:(NSURL *)url;

@end
