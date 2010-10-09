//
//  IJItemMatrix.h
//  InsideJob
//
//  Created by Adam Preble on 10/8/10.
//  Copyright 2010 Adam Preble. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IJItemMatrix : NSMatrix {

}

+ (id)itemMatrixWithFrame:(NSRect)frame rows:(int)rows columns:(int)cols;

@end
