//
//  NSData+ZipCompression.m
//  OpenStreetPad
//
//  Created by Thomas Davie on 21/04/2012.
//  Copyright (c) 2012 Thomas Davie. All rights reserved.
//

#import "NSData+ZipCompression.h"

#import <zlib.h>

@implementation NSData (ZipCompression)

- (NSData *)dataByDecompressingZip
{
	if ([self length] == 0)
    {
        return self;
    }
    
	NSUInteger fullLength = [self length];
	NSUInteger halfLength = fullLength / 2;
    
	NSMutableData *decompressed = [NSMutableData dataWithLength:fullLength + halfLength];
	BOOL done = NO;
	int status;
    
	z_stream stream;
	stream.next_in = (Bytef *)[self bytes];
	stream.avail_in = (uint)[self length];
	stream.total_out = 0;
	stream.zalloc = Z_NULL;
	stream.zfree = Z_NULL;
    
	if (inflateInit(&stream) != Z_OK)
    {
        return nil;
    }
    
	while (!done)
	{
		// Make sure we have enough room and reset the lengths.
		if (stream.total_out >= [decompressed length])
        {
			[decompressed increaseLengthBy:halfLength];
        }
		stream.next_out = [decompressed mutableBytes] + stream.total_out;
		stream.avail_out = (uint)([decompressed length] - stream.total_out);
        
		// Inflate another chunk.
		status = inflate(&stream, Z_SYNC_FLUSH);
		if (status == Z_STREAM_END)
        {
            done = YES;
        }
		else if (status != Z_OK)
        {
            break;
        }
	}
	if (inflateEnd(&stream) != Z_OK)
    {
        return nil;
    }
    
	// Set real length.
	if (done)
	{
		[decompressed setLength:stream.total_out];
		return [NSData dataWithData:decompressed];
	}
	else
    {
        return nil;
    }
}

- (NSData *)dataByCompressingZip
{
	if ([self length] == 0)
    {
        return self;
    }
	
	z_stream stream;
    
	stream.zalloc = Z_NULL;
	stream.zfree = Z_NULL;
	stream.opaque = Z_NULL;
	stream.total_out = 0;
	stream.next_in = (Bytef *)[self bytes];
	stream.avail_in = (uint)[self length];
    
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
    
	if (deflateInit(&stream, Z_DEFAULT_COMPRESSION) != Z_OK)
    {
        return nil;
    }
    
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chuncks for expansion
	do
    {
		if (stream.total_out >= [compressed length])
        {
			[compressed increaseLengthBy:16384];
        }
		
		stream.next_out = [compressed mutableBytes] + stream.total_out;
		stream.avail_out = (uint)([compressed length] - stream.total_out);
		
		deflate(&stream, Z_FINISH);  
	}
    while (stream.avail_out == 0);
	
	deflateEnd(&stream);
	
	[compressed setLength:stream.total_out];
	return [NSData dataWithData:compressed];
}

@end
