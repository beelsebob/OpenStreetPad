//
//  NSData+ZipCompression.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 21/04/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ZipCompression)

- (NSData *)dataByDecompressingZip;
- (NSData *)dataByCompressingZip;

@end
