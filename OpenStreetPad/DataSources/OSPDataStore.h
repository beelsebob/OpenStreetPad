//
//  OSPDataStore.h
//  OpenStreetPad
//
//  Created by Thomas Davie on 28/02/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OSPDataStore <NSObject>

- (void)addObject:(OSPAPIObject *)apiObject;

@end

@protocol OSPPersistingStore <OSPDataStore>

- (void)save;

@end
