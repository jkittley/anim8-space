//
//  OpenCVWrapper.h
//  Anim8
//
//  Created by Jacob Kittley-Davies on 10/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface OpenCVWrapper : NSObject
+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image;
+ (nullable UIImage *)feedback:(nonnull UIImage*)image arg2:(nonnull NSString*)alg arg3:(nonnull NSString*)fb arg4:(bool)kpon arg5:(bool)kpadv arg6:(nullable UIImage *)keyFrame arg7:(nonnull NSString *)algDesc arg8:(double)orbLimit;
+ (bool)testfirstimage:(nonnull UIImage*)key arg2:(nonnull NSString*)alg;
+ (nullable UIImage *)transform:(nonnull UIImage*)key arg2:(nonnull UIImage*)img arg3:(nonnull NSString*)algFeat arg4:(nonnull NSString*)algDesc arg5:(double)orbLimit;
+ (nonnull UIImage *)rotate:(nonnull UIImage*)img arg2:(double)angle;

+ (BOOL)catchException:(void(^_Nullable)())tryBlock error:(__autoreleasing NSError *_Nullable*)error;


@end
