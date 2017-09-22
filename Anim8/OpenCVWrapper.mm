//
//  OpenCVWrapper.m
//  Anim8
//
//  Created by Jacob Kittley-Davies on 10/08/2017.
//  Copyright © 2017 Jacob Kittley-Davies. All rights reserved.
//

#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/features2d/features2d.hpp>
#import "opencv2/nonfree/nonfree.hpp"
#import <Foundation/Foundation.h>
#import "OpenCVWrapper.h"

using namespace std;

int FB_MODE_BLURRED  = 0;
int FB_MODE_COLOURED = 1;
int FB_MODE_REVEAL   = 2;
int FB_MODE_HEATMAP  = 3;
int FB_MODE_REVEAL_PAPER = 4;
float reveal_factor = 0.25;
float reveal_factor_paper = 0.001;

/// Converts an UIImage to Mat.
/// Orientation of UIImage will be lost.
static void UIImageToMat(UIImage *image, cv::Mat &mat) {
    // Create a pixel buffer.
    NSInteger width = CGImageGetWidth(image.CGImage);
    NSInteger height = CGImageGetHeight(image.CGImage);
    CGImageRef imageRef = image.CGImage;
    cv::Mat mat8uc4 = cv::Mat((int)height, (int)width, CV_8UC4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(mat8uc4.data, mat8uc4.cols, mat8uc4.rows, 8, mat8uc4.step, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    // Draw all pixels to the buffer.
    cv::Mat mat8uc3 = cv::Mat((int)width, (int)height, CV_8UC3);
    cv::cvtColor(mat8uc4, mat8uc3, CV_RGBA2BGR);
    mat = mat8uc3;
}

/// Converts a Mat to UIImage.
static UIImage *MatToUIImage(cv::Mat &mat) {
    // Create a pixel buffer.
    if (mat.elemSize() < 1 || mat.elemSize() > 3) {
        throw "MatToUIImage mat is missing of wrong shape";
    }
    cv::Mat matrgb;
    if (mat.elemSize() == 1) {
        cv::cvtColor(mat, matrgb, CV_GRAY2RGB);
    } else if (mat.elemSize() == 3) {
        cv::cvtColor(mat, matrgb, CV_BGR2RGB);
    }
    // Change a image format.
    NSData *data = [NSData dataWithBytes:matrgb.data length:(matrgb.elemSize() * matrgb.total())];
    CGColorSpaceRef colorSpace;
    if (matrgb.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(matrgb.cols, matrgb.rows, 8, 8 * matrgb.elemSize(), matrgb.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return image;
}



/// Restore the orientation to image.
static UIImage *RestoreUIImageOrientation(UIImage *processed, UIImage *original) {
    if (processed.imageOrientation == original.imageOrientation) { return processed; }
    return [UIImage imageWithCGImage:processed.CGImage scale:1.0 orientation:original.imageOrientation];
}




// ---------------------------------------------------------------------------------------------------------------

//
// Feadback - Reveal
//
static void FeedbackAlgorithmVision(cv::Mat &src, vector<cv::KeyPoint> keypoints, cv::Mat &dst, int mode) {
    cv::Mat mask(src.size(), src.type(), cv::Scalar::all(0));
    for(int i = 0; i < keypoints.size(); i++){
        cv::circle(mask, keypoints[i].pt, keypoints[i].size / 2, cv::Scalar(255, 255, 255), -1);
    }
    cv::Mat invMask;
    cv::bitwise_not(mask, invMask);
    cv::Mat foreground;
    cv::Mat background;
    
    if (mode == FB_MODE_COLOURED) {
        foreground = src;
        cv::cvtColor(src, background, cv::COLOR_BGR2GRAY);
        cv::cvtColor(background, background, cv::COLOR_GRAY2BGR);
    } else if (mode == FB_MODE_REVEAL) {
        foreground = src;
        cv::cvtColor(src, background, cv::COLOR_BGR2GRAY);
        background *= reveal_factor;
        cv::cvtColor(background, background, cv::COLOR_GRAY2BGR);
    } else if (mode == FB_MODE_REVEAL_PAPER) {
        foreground = src;
        cv::cvtColor(src, background, cv::COLOR_BGR2GRAY);
        background *= reveal_factor_paper;
        cv::cvtColor(background, background, cv::COLOR_GRAY2BGR);
    } else if (mode == FB_MODE_BLURRED) {
        foreground = src;
        cv::blur(src, background, cv::Size( 15, 15));
    } else {
        throw "UNKNOWN FB TYPE";
    }
    
    cv::bitwise_and(background, invMask, background);
    cv::bitwise_and(foreground, mask, foreground);
    cv::add(background, foreground, dst);
}

// Feedback Keypoints Only
static void FeedbackKeypoints(cv::Mat &src, vector<cv::KeyPoint> keypoints, cv::Mat &dst) {
    for(int i = 0; i < keypoints.size(); i++){
        cv::circle(dst, keypoints[i].pt, 3, cv::Scalar(10, 110, 250), -1);
        cv::circle(dst, keypoints[i].pt, 3, cv::Scalar(0, 0, 0), 1);
    }
}

//FeedbackKeypointDensity(bgrMat, keypoints, bgrMat, 20, 50, 255, FB_MODE_BLURRED, 15)
static void FeedbackKeypointDensity(cv::Mat &src, vector<cv::KeyPoint> keypoints, cv::Mat &dst, int bin_factor, int thresh_low, int thresh_high, int mode, int blur_kernal_w) {
    
    
    // Make heatmap
    int r = floor(src.rows / bin_factor);
    int c = floor(src.cols / bin_factor);
    int w = src.cols;
    int h = src.rows;
    
    if (keypoints.size() == 0) {
        dst = src;
        return;
    }
    
    cv::Mat heatmap(r, c, CV_8UC1, cv::Scalar::all(0));
    
    // Basic
//    for(int i = 0; i < keypoints.size(); i++){
//        int x = floor(keypoints[i].pt.x / bin_factor);
//        int y = floor(keypoints[i].pt.y / bin_factor);
//        heatmap.data[y*c+x] += 1;
//    }
    
    // Wider
    for(int i = 0; i < keypoints.size(); i++){
        int x = floor(keypoints[i].pt.x / bin_factor);
        int y = floor(keypoints[i].pt.y / bin_factor);
        for(int yi=y-1; yi<=y+1; yi++) {
            for(int xi=x-1; xi<=x+1; xi++) {
                try {
                    heatmap.data[yi*c+xi] += 1;
                } catch(...) {
                    // Catch out of bounds
                }
            }
        }
        // Bosst middle
        heatmap.data[y*c+x] += 2;
    }

    // Normalise it 0-255
    double min, max;
    cv::minMaxLoc(heatmap, &min, &max);
    heatmap *= 255 / max;
    
    // Resize and BLUR
    cv::Mat resized;
    cv::Mat blurred;
    cv::resize(heatmap, resized, cv::Size(w,h), cv::INTER_CUBIC);
    cv::blur(resized, blurred, cv::Size(blur_kernal_w, blur_kernal_w));
    
    // Make mask
    cv::Mat mask;
    cv::threshold(blurred, mask, thresh_low, thresh_high, cv::THRESH_BINARY);
    cv::Mat invMask = 255 - mask;
    cv::cvtColor(mask, mask, cv::COLOR_GRAY2BGR);
    cv::cvtColor(invMask, invMask, cv::COLOR_GRAY2BGR);

    // Make gray
    cv::Mat background;
    cv::Mat foreground;
    
    if (mode == FB_MODE_COLOURED) {
        foreground = src;
        cv::cvtColor(src, background, cv::COLOR_BGR2GRAY);
        cv::cvtColor(background, background, cv::COLOR_GRAY2BGR);
    } else if (mode == FB_MODE_REVEAL) {
        foreground = src;
        cv::cvtColor(src, background, cv::COLOR_BGR2GRAY);
        background *= reveal_factor;
        cv::cvtColor(background, background, cv::COLOR_GRAY2BGR);
    } else if (mode == FB_MODE_BLURRED) {
        foreground = src;
        cv::blur(src, background, cv::Size( 15, 15));
    } else if (mode == FB_MODE_HEATMAP) {
        background = src;
        cv::cvtColor(blurred, foreground, cv::COLOR_GRAY2BGR);
        cv::applyColorMap(foreground, foreground, cv::COLORMAP_RAINBOW);
    } else {
        throw "UNKNOWN FB TYPE";
    }
    
    cv::bitwise_and(background, invMask, background);
    cv::bitwise_and(foreground, mask, foreground);
    cv::Mat finalmat;
    cv::add(background, foreground, dst);
}


static vector<cv::KeyPoint> getKeypoints(cv::Mat &src, NSString* algFeat) {
    
    vector<cv::KeyPoint> keypoints;
    
    if ([algFeat  isEqual: @"sift"]) {
        cv::SiftFeatureDetector detector;
        detector.detect(src, keypoints);
        
    } else if ([algFeat  isEqual: @"surf"]) {
        cv::SurfFeatureDetector detector;
        detector.detect(src, keypoints);
        
    } else if ([algFeat  isEqual: @"orb"]) {
        cv::OrbFeatureDetector detector;
        detector.detect(src, keypoints);
        
    } else if ([algFeat  isEqual: @"harris"]) {
        cv::cornerHarris(src, keypoints, 2, 3, 0.04);
        
    } else if ([algFeat  isEqual: @"fast"]) {
        cv::FastFeatureDetector detector;
        detector.detect(src, keypoints);

    } else {
        throw "No algorithm";
    }
    
    return keypoints;
}


static cv::Mat getDescriptors(cv::Mat &src, vector<cv::KeyPoint> keypoints, NSString* algDesc) {
    
    cv::Mat descriptors;
    
    if ([algDesc  isEqual: @"sift"]) {
        printf("Using SIFT extractor\n");
        cv::SiftDescriptorExtractor extractor;
        extractor.compute(src, keypoints, descriptors);
    } else if ([algDesc  isEqual: @"surf"]) {
        printf("Using SURF extractor\n");
        cv::SurfDescriptorExtractor extractor;
        extractor.compute(src, keypoints, descriptors);
    } else if ([algDesc  isEqual: @"orb"]) {
        printf("Using ORB extractor\n");
        cv::OrbDescriptorExtractor extractor;
        extractor.compute(src, keypoints, descriptors);
    } else {
        throw "No algorithm";
    }
    
    return descriptors;
}


static bool isGoodHomography(cv::Mat H) {
    const double det = H.at<double>(0, 0) * H.at<double>(1, 1) - H.at<double>(1, 0) * H.at<double>(0, 1);
    if (det < 0)
        return false;
    
    const double N1 = sqrt(H.at<double>(0, 0) * H.at<double>(0, 0) + H.at<double>(1, 0) * H.at<double>(1, 0));
    if (N1 > 4 || N1 < 0.1)
        return false;
    
    const double N2 = sqrt(H.at<double>(0, 1) * H.at<double>(0, 1) + H.at<double>(1, 1) * H.at<double>(1, 1));
    if (N2 > 4 || N2 < 0.1)
        return false;
    
    const double N3 = sqrt(H.at<double>(2, 0) * H.at<double>(2, 0) + H.at<double>(2, 1) * H.at<double>(2, 1));
    if (N3 > 0.002)
        return false;
    
    return true;
}


// ---------------------------------------------------------------------------------------
// Functions available to SWIFT wrapper
// ---------------------------------------------------------------------------------------


@implementation OpenCVWrapper


//
// Feedback - Provide feedback based on algorithm and feedback type
//

+ (nullable UIImage *)feedback:(nonnull UIImage *)image arg2:(nonnull NSString *)algFeat arg3:(nonnull NSString *)fb arg4:(bool)kpon arg5:(bool)kpadv {
    cv::initModule_nonfree();
    cv::Mat bgrMat;
    UIImageToMat(image, bgrMat);
    cv::Mat grayMat;
    cv::cvtColor(bgrMat, grayMat, CV_BGR2GRAY);
    cv::Mat outMat;
    
    try {
   
        vector<cv::KeyPoint> keypoints;
        try {
            keypoints = getKeypoints(grayMat, algFeat);
        } catch (...) {
            return NULL;
        }
        
        // Keypoints
        if ([fb  isEqual: @"keypoints"]) {
            outMat = bgrMat;
            kpon = true;
        // Density
        } else if ([fb  isEqual: @"density reveal"]) {
            //FeedbackAlgorithmSees(bgrMat, keypoints, bgrMat);
            FeedbackKeypointDensity(bgrMat, keypoints, outMat, 20, 50, 255, FB_MODE_REVEAL, 15);
        } else if ([fb  isEqual: @"density heatmap"]) {
            FeedbackKeypointDensity(bgrMat, keypoints, outMat, 20, 50, 255, FB_MODE_HEATMAP,  15);
        } else if ([fb  isEqual: @"density blurred"]) {
            FeedbackKeypointDensity(bgrMat, keypoints, outMat, 20, 50, 255, FB_MODE_BLURRED, 15);
        } else if ([fb  isEqual: @"density colour"]) {
            FeedbackKeypointDensity(bgrMat, keypoints, outMat, 20, 50, 255, FB_MODE_COLOURED, 15);
        
        // Algorithm Vision
        } else if ([fb  isEqual: @"vision reveal"]) {
            FeedbackAlgorithmVision(bgrMat, keypoints, outMat, FB_MODE_REVEAL);
        } else if ([fb  isEqual: @"vision reveal paper"]) {
            FeedbackAlgorithmVision(bgrMat, keypoints, outMat, FB_MODE_REVEAL_PAPER);
        } else if ([fb  isEqual: @"vision blurred"]) {
            FeedbackAlgorithmVision(bgrMat, keypoints, outMat, FB_MODE_BLURRED);
        } else if ([fb  isEqual: @"vision colour"]) {
            FeedbackAlgorithmVision(bgrMat, keypoints, outMat, FB_MODE_COLOURED);
        } else {
            outMat = bgrMat;
        }
        
        // Extra Keypoints
        if (kpon) {
            if (kpadv) {
                cv::drawKeypoints(outMat, keypoints, outMat, cv::Scalar::all(-1), 4);
            } else {
                FeedbackKeypoints(outMat, keypoints, outMat);
            }
        }
        
        // Return
        UIImage *kpImage = MatToUIImage(outMat);
        return RestoreUIImageOrientation(kpImage, image);
        
    } catch (const std::exception &exc) {
        // catch anything thrown within try block that derives from std::exception
        std::cerr << exc.what();
        return NULL;
    } catch (...) {
        return NULL;
    }
}


//
// Transform an image to match its predicesor
//

+ (nonnull UIImage *)cvtColorBGR2GRAY:(nonnull UIImage *)image {
    cv::Mat bgrMat;
    UIImageToMat(image, bgrMat);
    cv::Mat grayMat;
    cv::cvtColor(bgrMat, grayMat, CV_BGR2GRAY);
    UIImage *grayImage = MatToUIImage(grayMat);
    return RestoreUIImageOrientation(grayImage, image);
}


//
// Grayscale image
//

+ (nonnull UIImage *)rotate:(nonnull UIImage*)img arg2:(double)angle {
    
    cv::Mat src;
    cv::Mat dst;
    UIImageToMat(img, src);
    
    cv::Point2f center(src.cols/2.0, src.rows/2.0);
    cv::Mat rot = cv::getRotationMatrix2D(center, angle, 1.0);
    // determine bounding rectangle
    cv::Rect bbox = cv::RotatedRect(center,src.size(), angle).boundingRect();
    // adjust transformation matrix
    rot.at<double>(0,2) += bbox.width/2.0 - center.x;
    rot.at<double>(1,2) += bbox.height/2.0 - center.y;
    
    cv::warpAffine(src, dst, rot, bbox.size());
    UIImage *kpImage = MatToUIImage(dst);
    return RestoreUIImageOrientation(kpImage, img);
}



//
// Test first image in animation - does it have enough key points?
//

+ (bool)testfirstimage:(nonnull UIImage*)key arg2:(nonnull NSString*)algFeat {
    cv::Mat bgrKey;
    UIImageToMat(key, bgrKey);
    
    cv::Mat grayKey;
    cv::cvtColor(bgrKey, grayKey, CV_BGR2GRAY);
    
    vector<cv::KeyPoint> keypoints = getKeypoints(grayKey, algFeat);
    
    if (keypoints.size() < 20) {
        return false;
    }
    return true;
}


//
// Transform an image to match its predicesor
//

+ (nullable UIImage *)transform:(nonnull UIImage*)key arg2:(nonnull UIImage*)img arg3:(nonnull NSString*)algFeat arg4:(nonnull NSString*)algDesc {
    cout << "------ Transforming -------" << endl;
    printf("Fetaure Alg: %s\n", [algFeat UTF8String]);
    printf("Descriptor Alg: %s\n", [algDesc UTF8String]);
    
    cv::initModule_nonfree();
    
    cv::Mat bgrKey;
    cv::Mat bgrImg;
    UIImageToMat(key, bgrKey);
    UIImageToMat(img, bgrImg);
    
    cv::Mat grayKey;
    cv::Mat grayImg;
    cv::cvtColor(bgrKey, grayKey, CV_BGR2GRAY);
    cv::cvtColor(bgrImg, grayImg, CV_BGR2GRAY);
    
    
    // Pick transform
    vector<cv::KeyPoint> kpKey;
    vector<cv::KeyPoint> kpImg;
    try {
        kpKey = getKeypoints(grayKey, algFeat);
        kpImg = getKeypoints(grayImg, algFeat);
    } catch (...) {
        printf("Keypoint generation failed\n");
        return NULL;
    }
    
    if (kpKey.size() < 4) {
        printf("too few points on key image\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Too few features on key image"];
        return NULL;
    }
    
    if (kpImg.size() < 4) {
        printf("too few points on captured image\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Too few features on captured image"];
        return NULL;
    }
    
    
    cv::Mat desKey;
    cv::Mat desImg;
    try {
        desKey = getDescriptors(grayKey, kpKey, algDesc);
        desImg = getDescriptors(grayImg, kpImg, algDesc);
    } catch (...) {
        printf("Descriptor generation failed\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Failed to generate descriptors"];
        return NULL;
    }
    
    if ( desKey.empty()) {
        printf("Key descriptors Empty\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Too few key descriptors"];
        return NULL;
    }

    if ( desImg.empty() ) {
        printf("Image descriptors Empty\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Too few image descriptors"];
        return NULL;
    }

    cout << "Key Descriptors size:" << desKey.size() << endl;
    cout << "Img Descriptors size:" << desImg.size() << endl;
    
    
    if(desKey.type()!=CV_32F) {
        desKey.convertTo(desKey, CV_32F);
    }
    
    if(desImg.type()!=CV_32F) {
        desImg.convertTo(desImg, CV_32F);
    }
    
    printf("Matching\n");
    
    cv::FlannBasedMatcher matcher;
    vector< cv::DMatch > matches;
    matcher.match(desImg, desKey, matches);
    double max_dist = 0; double min_dist = 100;
    
    //-- Quick calculation of max and min distances between keypoints
    for( int i = 0; i < desImg.rows; i++ )
    { double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    //-- Draw only "good" matches (i.e. whose distance is less than 2*min_dist,
    //-- or a small arbitary value ( 0.02 ) in the event that min_dist is very small)
    //-- PS.- radiusMatch can also be used here.
    vector< cv::DMatch > good_matches;
    
    for( int i = 0; i < desImg.rows; i++ ) {
        if( matches[i].distance <= max(2*min_dist, 0.02) ) {
            good_matches.push_back( matches[i]);
        }
    }
    
    //-- Draw only "good" matches
    //cv::Mat img_matches;
    //cv::drawMatches( bgrImg, kpImg, bgrKey, kpKey, good_matches, img_matches, cv::Scalar::all(-1), cv::Scalar::all(-1), vector<char>(), cv::DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
    
    
    //-- Localize the object
    std::vector<cv::Point2f> src;
    std::vector<cv::Point2f> dst;
    for( int i = 0; i < good_matches.size(); i++ ) {
        //-- Get the keypoints from the good matches
        src.push_back( kpImg[ good_matches[i].queryIdx ].pt );
        dst.push_back( kpKey[ good_matches[i].trainIdx ].pt );
    }
    
    
    cout << "Number of good Matches: " << good_matches.size() <<endl;
    
    if (good_matches.size() < 4) {
        printf("Too few matches\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Insufficient feature matches"];
        return NULL;
    }
    
    // Find perspective
    cv::Mat M = findHomography( src, dst, CV_RANSAC );
    
    cout << M << endl;
    if (!isGoodHomography(M)) {
        printf("Bad Homography\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Insufficient feature matches to create good homography"];
        return NULL;
    }
    
    // Make warp for mask
    cv::Mat img_warped;
    cv::warpPerspective(bgrImg, img_warped, M, bgrImg.size(), cv::INTER_LINEAR, cv::BORDER_CONSTANT);
    
    // Make warp for use
    //cv::Mat img_replicate;
    //cv::warpPerspective(bgrImg, img_replicate, M, bgrImg.size(), cv::INTER_LINEAR, cv::BORDER_REPLICATE);

    // Draw warped image over the key images so that the frame appears full
    cv::Mat mask;
    cv::inRange(img_warped, cv::Scalar(0,0,0), cv::Scalar(5,5,5), mask);
    
    // Shirk mask a little
    int size = 6;
    cv::Mat element = getStructuringElement(cv::MORPH_CROSS, cv::Size(2 * size + 1, 2 * size + 1), cv::Point(size, size) );
    cv::dilate( mask, mask, element );
    
    cv::Mat merged = bgrKey.clone();
    img_warped.copyTo(merged, 255-mask);
    
    UIImage *kpImage = MatToUIImage(merged);
    //UIImage *kpImage = MatToUIImage(img_warped);
    return RestoreUIImageOrientation(kpImage, img);
}


+ (BOOL)catchException:(void(^)())tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
        [userInfo setValue:exception.reason forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:exception.name forKey:NSUnderlyingErrorKey];

        *error = [[NSError alloc] initWithDomain:exception.name
                                            code:0
                                        userInfo:userInfo];
        return NO;
    }
}



@end
