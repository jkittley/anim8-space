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

int ORB_KP_NUMBER = 500;
int GOOD_MIN_DIST_MULTIPLIER = 3;
bool CHECK_HOMOGRAPHY = false;


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
        throw "Unknown density feedback visualisation";
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
        cv::OrbFeatureDetector detector = cv::ORB(ORB_KP_NUMBER);
        detector.detect(src, keypoints);
        
    } else if ([algFeat  isEqual: @"harris"]) {
        cv::cornerHarris(src, keypoints, 2, 3, 0.04);
        
    } else if ([algFeat  isEqual: @"fast"]) {
        cv::FastFeatureDetector detector;
        detector.detect(src, keypoints);

    } else {
        throw "Unknown visualisation algorithm";
    }
    
    return keypoints;
}


static cv::Mat getDescriptors(cv::Mat &src, vector<cv::KeyPoint> keypoints, NSString* algDesc) {
    
    cv::Mat descriptors;
    
    if ([algDesc  isEqual: @"sift"]) {
        //printf("Using SIFT extractor\n");
        cv::SiftDescriptorExtractor extractor;
        extractor.compute(src, keypoints, descriptors);
    } else if ([algDesc  isEqual: @"surf"]) {
        //printf("Using SURF extractor\n");
        cv::SurfDescriptorExtractor extractor;
        extractor.compute(src, keypoints, descriptors);
    } else if ([algDesc  isEqual: @"orb"]) {
        //printf("Using ORB extractor\n");
        cv::OrbDescriptorExtractor extractor;
        extractor.compute(src, keypoints, descriptors);
    } else {
        throw "Unknown processing algorithm";
    }
    
    return descriptors;
}

void rot90(cv::Mat &matImage, int rotflag){
    //1=CW, 2=CCW, 3=180
    if (rotflag == 1){
        transpose(matImage, matImage);
        flip(matImage, matImage,1); //transpose+flip(1)=CW
    } else if (rotflag == 2) {
        transpose(matImage, matImage);
        flip(matImage, matImage,0); //transpose+flip(0)=CCW
    } else if (rotflag ==3){
        flip(matImage, matImage,-1);    //flip(-1)=180
    } else if (rotflag != 0){ //if not 0,1,2,3:
        cout  << "Unknown rotation flag(" << rotflag << ")" << endl;
    }
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

static bool getMatches(cv::Mat grayKey, cv::Mat grayImg, vector<cv::KeyPoint>kpKey, vector<cv::KeyPoint>kpImg, NSString* algFeat, NSString* algDesc, vector<cv::DMatch> &good_matches, std::vector<cv::Point2f> &src_match_points, std::vector<cv::Point2f> &dst_match_points) {
    
    cv::Mat desKey;
    cv::Mat desImg;
    try {
        desKey = getDescriptors(grayKey, kpKey, algDesc);
        desImg = getDescriptors(grayImg, kpImg, algDesc);
    } catch (...) {
        printf("Descriptor generation failed\n");
//        [NSException raise:@"FrameTransformError"
//                    format:@"Internal error - Failed to generate descriptors"];
        return false;
    }
    
    if ( desKey.empty()) {
        printf("Key descriptors Empty\n");
//        [NSException raise:@"FrameTransformError"
//                    format:@"Internal error - Too few key descriptors"];
        return false;
    }
    
    if ( desImg.empty() ) {
        printf("Image descriptors Empty\n");
//        [NSException raise:@"FrameTransformError"
//                    format:@"Internal error - Too few image descriptors"];
        return false;
    }
    
    if(desKey.type()!=CV_32F) {
        desKey.convertTo(desKey, CV_32F);
    }
    
    if(desImg.type()!=CV_32F) {
        desImg.convertTo(desImg, CV_32F);
    }
    
    cv::FlannBasedMatcher matcher;
    vector< cv::DMatch > matches;
    matcher.match(desImg, desKey, matches);
    double max_dist = 0; double min_dist = 10000000;
    
    //-- Quick calculation of max and min distances between keypoints
    for( int i = 0; i < desImg.rows; i++ ) {
        double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    
    
    //-- Draw only "good" matches (i.e. whose distance is less than 2*min_dist,
    //-- or a small arbitary value ( 0.02 ) in the event that min_dist is very small)
    //-- PS.- radiusMatch can also be used here.
    
    
    //cout << "MIN DIST:" << min_dist <<endl;
    
    // If min dist is too high then the moving objects will affect the transformation
    for( int i = 0; i < desImg.rows; i++ ) {
        if( matches[i].distance <= max( GOOD_MIN_DIST_MULTIPLIER * min_dist, 0.02) ) {
            good_matches.push_back( matches[i] );
        }
    }
    
    
    
    

    //-- Localize the object
    for( int i = 0; i < good_matches.size(); i++ ) {
        //-- Get the keypoints from the good matches
        src_match_points.push_back( kpImg[ good_matches[i].queryIdx ].pt );
        dst_match_points.push_back( kpKey[ good_matches[i].trainIdx ].pt );
    }
    
    if (good_matches.size() < 4) {
        printf("Too few matches\n");
//        [NSException raise:@"FrameTransformError"
//                    format:@"Insufficient detail to process the photo. Try retaking this photo or the one it is being compared to"];
        return false;
    }
    
    return true;
}
    

// Feedback Matches
static void FeedbackMatchingKeypoints(cv::Mat &bgrMat, cv::Mat &grayMat, UIImage* keyImage, cv::Mat &outMat, NSString* algFeat, NSString* algDesc, bool showAll) {
    
    cv::Mat bgrMatKey;
    UIImageToMat(keyImage, bgrMatKey);
    cv::Mat grayMatKey;
    cv::cvtColor(bgrMatKey, grayMatKey, CV_BGR2GRAY);
    
    float scale = 1;
    if ([algDesc  isEqual: @"sift"]) {
        scale = 0.5;
    } else if ([algDesc  isEqual: @"surf"]) {
        scale = 0.8;
    } else if ([algDesc  isEqual: @"orb"]) {
        scale = 1;
    }
    
    cv::resize(grayMatKey, grayMatKey, cv::Size(), scale, scale);
    cv::resize(grayMat, grayMat, cv::Size(), scale, scale);
    cv::resize(bgrMatKey, bgrMatKey, cv::Size(), scale, scale);
    cv::resize(bgrMat, bgrMat, cv::Size(), scale, scale);
    
    outMat = bgrMat;
    
    vector<cv::KeyPoint> keypointsKey = getKeypoints(grayMatKey, algFeat);
    vector<cv::KeyPoint> keypointsCap = getKeypoints(grayMat, algFeat);
    
    // All Keypoints
    if (showAll) {
        for(int i = 0; i < keypointsCap.size(); i++){
            cv::circle(outMat, keypointsCap[i].pt, 1, cv::Scalar(255, 240, 200), -1);
            cv::circle(outMat, keypointsCap[i].pt, 2, cv::Scalar(135, 135, 135), 1);
        }
    }
    
    // Matches
    if (keypointsKey.size() > 4 && keypointsCap.size() > 4) {
        vector< cv::DMatch > good_matches;
        vector< cv::Point2f > src_match_points;
        vector< cv::Point2f > dst_match_points;
        //bool success =
        getMatches(grayMatKey, grayMat, keypointsKey, keypointsCap, algFeat, algDesc, good_matches, src_match_points, dst_match_points);
        //if (success) {
            //cv::drawMatches(bgrMat, keypoints, bgrMatKey, keypointsKey, good_matches, outMat, cv::Scalar::all(-1), cv::Scalar::all(-1), vector<char>(), cv::DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS);
            
            for(int i = 0; i < src_match_points.size(); i++){
                cv::circle(outMat, src_match_points[i], 1, cv::Scalar(10, 110, 250), -1);
                cv::circle(outMat, src_match_points[i], 2, cv::Scalar(0, 0, 0), 1);
            }
            
        //}
    }
}

static void CannyThreshold(cv::Mat& src_gray, cv::Mat& detected_edges) {
    int lowThreshold = 5;
    int ratio = 3;
    int kernel_size = 3;
    /// Reduce noise with a kernel 3x3
    cv::blur( src_gray, detected_edges, cv::Size(3,3) );
    /// Canny detector
    cv::Canny( detected_edges, detected_edges, lowThreshold, lowThreshold*ratio, kernel_size);
}

static void rotateMat(cv::Mat& src, double angle, cv::Mat& dst){
    cv::Point2f ptCp(src.cols*0.5, src.rows*0.5);
    cv::Mat M = cv::getRotationMatrix2D(ptCp, angle, 1.0);
    cv::warpAffine(src, dst, M, cv::Size(src.rows, src.cols), cv::INTER_CUBIC); //Nearest is too rough,
}


static void SideBySide(cv::Mat &bgrLeft, cv::Mat &bgrRight, cv::Mat &bgrOutput) {
    cv::resize(bgrRight, bgrRight, bgrLeft.size());
    cv::Mat sideBySide;
    cv::hconcat(bgrLeft, bgrRight, sideBySide);
    cv::copyMakeBorder( sideBySide, bgrOutput, bgrLeft.rows/2, bgrLeft.rows/2, 0, 0, cv::BORDER_CONSTANT, cv::Scalar(0,0,0));
}

static void PictureInPicture(cv::Mat &bgrBig, cv::Mat &bgrSmall, cv::Mat &bgrOutput) {
    cv::Mat bgrPip;
    cv::resize(bgrSmall, bgrPip, cv::Size(), 0.3, 0.3);
    cv::copyMakeBorder(bgrPip, bgrPip, 2,2,2,2, cv::BORDER_CONSTANT, cv::Scalar(10, 110, 250));
    cv::resize(bgrBig, bgrOutput, cv::Size(), 1, 1);
    
    // Define roi area (it has small image dimensions).
    cv::Rect roi = cv::Rect(bgrBig.cols - bgrPip.cols - 5, 5, bgrPip.cols, bgrPip.rows);
    // Take a sub-view of the large image
    cv::Mat subView = bgrOutput(roi);
    // Copy contents of the small image to large
    bgrPip.copyTo(subView);
    
}


// Feedback Pipeline End
static void FeedbackPipelineEnd(cv::Mat &bgrMat, cv::Mat &grayMat, UIImage* keyImage, cv::Mat &outMat, NSString* algFeat, NSString* algDesc, int showMode) {
    
    // No Keyimage i.e. this is the first image to be captured
    if (keyImage == NULL) {
        outMat = bgrMat;
        return;
    }
    
    cv::Mat bgrMatKey;
    UIImageToMat(keyImage, bgrMatKey);
    rotateMat(bgrMatKey, 270.0, bgrMatKey);
    cv::resize(bgrMatKey, bgrMatKey, bgrMat.size());
    
    cv::Mat grayMatKey;
    cv::cvtColor(bgrMatKey, grayMatKey, CV_BGR2GRAY);
    
    // Scale image to speed up based on algorithm used
    float scale = 1;
    if ([algDesc  isEqual: @"sift"]) {
        scale = 0.5;
    } else if ([algDesc  isEqual: @"surf"]) {
        scale = 0.8;
    } else if ([algDesc  isEqual: @"orb"]) {
        scale = 1;
    }
    if (scale != 1) {
        cv::resize(grayMatKey, grayMatKey, cv::Size(), scale, scale);
        cv::resize(grayMat, grayMat, cv::Size(), scale, scale);
        cv::resize(bgrMatKey, bgrMatKey, cv::Size(), scale, scale);
        cv::resize(bgrMat, bgrMat, cv::Size(), scale, scale);
    }
    
    
    // Basic setup
    if (showMode==1) {
        cv::Mat errorMat(bgrMat.rows, bgrMat.cols, CV_8UC3, cv::Scalar(139,0,0));;
        SideBySide(bgrMat, errorMat, outMat);
    } else if (showMode==2) {
        outMat = bgrMat;
    } else if (showMode==3) {
        cv::Mat errorMat(bgrMat.rows, bgrMat.cols, CV_8UC3, cv::Scalar(139,0,0));;
        PictureInPicture(bgrMat, errorMat, outMat);
    } else {
        outMat = bgrMat;
    }
        
    vector<cv::KeyPoint> keypointsKey = getKeypoints(grayMatKey, algFeat);
    vector<cv::KeyPoint> keypointsCap = getKeypoints(grayMat, algFeat);
    
    // Too few key points return half black
    if (keypointsKey.size() < 4 || keypointsCap.size() < 4) {
        return;
    }
    
    // Find perspective
    vector< cv::DMatch > good_matches;
    vector< cv::Point2f > src_match_points;
    vector< cv::Point2f > dst_match_points;
    getMatches(grayMatKey, grayMat, keypointsKey, keypointsCap, algFeat, algDesc, good_matches, src_match_points, dst_match_points);
    
    cv::Mat warped;
    cv::Mat merged = bgrMatKey.clone();
   
    
    try {
        cv::Mat M = findHomography(src_match_points, dst_match_points, CV_RANSAC);
        cv::warpPerspective(bgrMat, warped, M, bgrMat.size(), cv::INTER_LINEAR, cv::BORDER_CONSTANT);

        cv::Mat mask;
        cv::inRange(warped, cv::Scalar(0,0,0), cv::Scalar(5,5,5), mask);

        // Shirk mask a little
        int size = 6;
        cv::Mat element = getStructuringElement(cv::MORPH_CROSS, cv::Size(2 * size + 1, 2 * size + 1), cv::Point(size, size) );
        cv::dilate( mask, mask, element );
        
        cout << warped.size() << endl;
        
        warped.copyTo(merged, 255-mask);
        
        
    } catch (cv::Exception& e) {
        return;
    }
    
    // Output
    if (showMode==1) {
        SideBySide(bgrMat, merged, outMat);
        
    } else if (showMode==2){
        cv::Mat canny;
        cv::cvtColor(merged, merged, CV_BGR2GRAY);
        CannyThreshold(merged, canny);
        cv::cvtColor(canny, canny, CV_GRAY2BGR);
        addWeighted( bgrMat, 1.0, canny, 0.8, 0.0, outMat);
    
    } else if (showMode==3) {
        PictureInPicture(bgrMat, merged, outMat);
   
    } else {
        outMat = bgrMat;
    }
    
}



// ---------------------------------------------------------------------------------------
// Functions available to SWIFT wrapper
// ---------------------------------------------------------------------------------------


@implementation OpenCVWrapper


//
// Feedback - Provide feedback based on algorithm and feedback type
//

+ (nullable UIImage *)feedback:(nonnull UIImage *)image arg2:(nonnull NSString *)algFeat arg3:(nonnull NSString *)fb arg4:(bool)kpon arg5:(bool)kpadv arg6:(nullable UIImage *)keyImage arg7:(nonnull NSString *)algDesc arg8:(double)orbLimit {
    cv::initModule_nonfree();
   
    // Set orb limit
    ORB_KP_NUMBER = orbLimit;
    cout << "ORB_KP_NUMBER:" << ORB_KP_NUMBER << endl;
    
    cv::Mat bgrMat;
    UIImageToMat(image, bgrMat);
    cv::Mat grayMat;
    cv::cvtColor(bgrMat, grayMat, CV_BGR2GRAY);
    cv::Mat outMat;
    
    try {
   
        vector<cv::KeyPoint> keypoints;
        if (![fb  isEqual: @"matching"]) {
            try {
                keypoints = getKeypoints(grayMat, algFeat);
            } catch (...) {
                return NULL;
            }
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
        
        // Matching
        } else if ([fb  isEqual: @"matches only"]) {
            if (keyImage != NULL) {
                FeedbackMatchingKeypoints(bgrMat, grayMat, keyImage, outMat, algFeat, algDesc, false);
            } else {
                outMat = bgrMat;
                kpon = true;
            }
        
        } else if ([fb  isEqual: @"matches all"]) {
            if (keyImage != NULL) {
                FeedbackMatchingKeypoints(bgrMat, grayMat, keyImage, outMat, algFeat, algDesc, true);
            } else {
                outMat = bgrMat;
                kpon = true;
            }
        
        // Output
        } else if ([fb  isEqual: @"output split"]) {
            FeedbackPipelineEnd(bgrMat, grayMat, keyImage, outMat, algFeat, algDesc, 1);
        } else if ([fb  isEqual: @"output canny"]) {
            FeedbackPipelineEnd(bgrMat, grayMat, keyImage, outMat, algFeat, algDesc, 2);
        } else if ([fb  isEqual: @"output picture in picture"]) {
            FeedbackPipelineEnd(bgrMat, grayMat, keyImage, outMat, algFeat, algDesc, 3);
            
            
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



+ (nullable UIImage *)transform:(nonnull UIImage*)key arg2:(nonnull UIImage*)img arg3:(nonnull NSString*)algFeat arg4:(nonnull NSString*)algDesc arg5:(double)orbLimit {
    cout << "------ Transforming -------" << endl;
    printf("Fetaure Alg: %s\n", [algFeat UTF8String]);
    printf("Descriptor Alg: %s\n", [algDesc UTF8String]);
    
    // Set orb limit
    ORB_KP_NUMBER = orbLimit;
    cout << "ORB_KP_NUMBER:" << ORB_KP_NUMBER << endl;
    
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
                    format:@"Too little detail in the comparison photo. Try retaking the first/last photo captured"];
        return NULL;
    }
    
    if (kpImg.size() < 4) {
        printf("too few points on captured image\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Too little detail in photo. Try again and make sure there is enough detail in the background."];
        return NULL;
    }
    
    vector< cv::DMatch > good_matches;
    vector< cv::Point2f > src_match_points;
    vector< cv::Point2f > dst_match_points;
    bool success = getMatches(grayKey, grayImg, kpKey, kpImg, algFeat, algDesc, good_matches, src_match_points, dst_match_points);
    
    if (!success) {
        [NSException raise:@"FrameTransformError"
            format:@"Anim8 failed to process the image correctly. Please try again. (Matches)"];
    }
    
    // Find perspective
    cv::Mat M = findHomography(src_match_points, dst_match_points, CV_RANSAC);
    
   
    if (CHECK_HOMOGRAPHY && !isGoodHomography(M)) {
        printf("Bad Homography\n");
        [NSException raise:@"FrameTransformError"
                    format:@"Anim8 failed to process the image correctly. Please try again"];
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
