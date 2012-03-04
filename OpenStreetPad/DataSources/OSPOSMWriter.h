//
//  OSPOSMWriter.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 03/03/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSPDataSource.h"

@interface OSPOSMWriter : NSObject

- (id)initWithStream:(NSOutputStream *)stream;

- (void)writeDataProvider:(id<OSPDataProvider>)dataProvider;

@end
