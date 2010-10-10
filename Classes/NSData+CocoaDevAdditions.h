//
//  NSData+CocoaDevAdditions.h
//  InsideJob
//
//  Created by Adam Preble on 10/6/10.
//

#import <Cocoa/Cocoa.h>


@interface NSData (CocoaDevAdditions)

- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
