//
//  OpenCvWrapper.h
//  OpenCv
//
//  Created by swedrowp on 12/03/2018.
//  Copyright © 2018 roche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCvWrapper : NSObject
+(int)compare:(UIImage*)img1 and:(UIImage*)img2;
+(UIImage *)sobelFilter:(UIImage *)image;
+(UIImage *)subtractBackground:(UIImage *)image;
+(UIImage *)contorusAndHull:(UIImage *)image;
+(UIImage *)recognizeHandGesture:(UIImage *)image;
@end
