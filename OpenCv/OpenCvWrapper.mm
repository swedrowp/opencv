//
//  OpenCvWrapper.m
//  OpenCv
//
//  Created by swedrowp on 12/03/2018.
//  Copyright © 2018 roche. All rights reserved.
//

#import "OpenCvWrapper.h"
#import <Foundation/Foundation.h>
#import "OpenCv-Bridging-Header.h"
#import <UIKit/UIKit.h>

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>


using namespace std;
using namespace cv;

@implementation OpenCvWrapper

+(UIImage *)sobelFilter:(UIImage *)image{
    Mat mat;
    UIImageToMat(image, mat);
    
    Mat gray;
    cvtColor(mat, gray, COLOR_BGR2GRAY);
    
    Mat edge;
    Canny(gray, edge, 100, 200);
    
    UIImage *result = MatToUIImage(edge);
    return result;
}

Ptr<BackgroundSubtractorMOG2> pMOG2 = createBackgroundSubtractorMOG2();
+(UIImage *)subtractBackground:(UIImage *)image{
    Mat matImg;
    Mat fgMaskMOG2;
    Mat grayImg;
    
    cvtColor(matImg, grayImg, COLOR_BGR2GRAY);
    
    UIImageToMat(image, matImg);
    pMOG2->apply(matImg, fgMaskMOG2);
    
    Mat combinedImg;
    bitwise_and(grayImg, fgMaskMOG2, combinedImg);
    
    Mat outputImg;
    cvtColor(combinedImg, outputImg, CV_GRAY2RGB);
    
    UIImage *result = MatToUIImage(outputImg);
    return result;
}

+(int)compare:(UIImage*)img1 and:(UIImage*)img2{
    Mat img1Mat;
    UIImageToMat(img1, img1Mat);
    
    Mat img2Mat;
    UIImageToMat(img2, img2Mat);
    
    Mat result;
    
    compare(img1Mat, img2Mat, result, CMP_EQ );
    int intResult = countNonZero(result);
    return intResult;
}

+(UIImage *)contorusAndHull:(UIImage *)image{
    Mat threshold_output;
    vector<vector<Point2i> > contours;
    vector<Vec4i> hierarchy;
    
    Mat matImg;
    UIImageToMat(image, matImg);
    
    Mat grayImg;
    cvtColor(matImg, grayImg, COLOR_BGR2GRAY);
    
    Mat blurImg;
//    GaussianBlur(fgMaskMOG2, blurImg, Size2i(5,5), 0);
    blur(grayImg, blurImg, Size2i(8,8));
    
    /// Detect edges using Threshold
    threshold( blurImg, threshold_output, 200, 255, THRESH_BINARY );
    
    /// Find contours
    findContours( threshold_output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, Point2i(0, 0) );
    
    /// Find the convex hull object for each contour
    vector<vector<Point2i> >hull( contours.size() );
    for( int i = 0; i < contours.size(); i++ )
    {
        convexHull( Mat(contours[i]), hull[i] );
    }
    
    /// Draw contours + hull results
    Mat drawing = Mat::zeros( threshold_output.size(), CV_8UC3 );
    for( int i = 0; i< contours.size(); i++ )
    {
        drawContours( drawing, contours, i, Scalar(255, 255, 255, 255), -1);
        drawContours( drawing, hull, i, Scalar(0, 255, 0, 255), 2, 8, vector<Vec4i>(), 0, Point2i() );
    }
    UIImage *result = MatToUIImage(threshold_output);
    return result;
}


//    cv::Rect rectangle(10,10,matImg.cols-10,matImg.rows-10);
//    cv::Mat resultImg; // segmentation result (4 possible values)
//    cv::Mat bgModel,fgModel; // the models (internally used)
//
//    cv::cvtColor(matImg , matImg , CV_RGBA2RGB);
//
//    // GrabCut segmentation
//    cv::grabCut(matImg,    // input image
//                resultImg,   // segmentation result
//                rectangle,// rectangle containing foreground
//                bgModel,fgModel, // models
//                100,        // number of iterations
//                cv::GC_INIT_WITH_RECT); // use rectangle
//
//




















+(UIImage *)recognizeHandGesture:(UIImage *)image{
    Mat matImg;
    UIImageToMat(image, matImg);
    
    Mat imgHSV;
    cvtColor(matImg, imgHSV, COLOR_BGR2HSV);
    
    Mat skinColorLower = Mat(1, 3, imgHSV.type(), {110,50,50});
    Mat skinColorUpper = Mat(1, 3, imgHSV.type(), {130,255,255});
    
    Mat rangeMask;
    cv::inRange(imgHSV, skinColorLower, skinColorUpper, rangeMask);
    
    Mat blurImg;
    blur(rangeMask, blurImg, Size2i(10,10));
    
    Mat tresholdOut;
    threshold( blurImg, tresholdOut, 200, 255, THRESH_BINARY );
    
    vector< vector<Point2i> > contours;
    vector<Vec4i> hierarchy;
    findContours( tresholdOut, contours, hierarchy, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
//    findContours( tresholdOut, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, Point2i(0, 0) );

    int ci = 0;
    double max_area = 0;
    vector<Point2i> cnt;
    for( int i = 0; i< contours.size(); i++ )
    {
        cnt = contours[i];
        double area = contourArea(cnt);
        if(area>max_area){
            max_area=area;
            ci=i;
        }
    }

    vector<vector<Point2i>> hulls( contours.size() );
    vector<vector<int>> hullsI(contours.size());
    vector<vector<Vec4i>> defects( contours.size() );
    for( int i = 0; i < contours.size(); i++ )
    {
        convexHull( contours[i], hulls[i] );
        convexHull( contours[i], hullsI[i], false, false );
        if (hullsI.size() > 3) {
            convexityDefects(contours[i], hullsI[i], defects[i]);
        }
    }

    if (max_area > 1000){
        drawContours( matImg, contours, ci, Scalar(0, 0, 255, 255), 3);
        drawContours( matImg, hulls, ci, Scalar(0, 255, 0, 255), 3);
        
        double maxDist = 100.0;
        vector<Point2i> contourPoints;
        vector<Point2i> defectPoints;
        for (int j=1; j<hulls[ci].size(); j++) {
            
            Point2i firstPoint = hulls[ci][j-1];
            Point2i secondPoint = hulls[ci][j];
            
            double dist = norm(secondPoint - firstPoint);
            
            if (dist > maxDist) {
                contourPoints.push_back(firstPoint);
//                for (int k=0; k<defects[ci].size(); k++) {
//                    const Vec4i defect = defects[ci][k];
//                    Point2i p1(contours[ci][defect[0]]);
//                    Point2i p2(contours[ci][defect[1]]);
//                    Point2i p3(contours[ci][defect[2]]);
//                    if (p1 == firstPoint) {
//                        defectPoints.push_back(p3);
//                    }
//                }
            }
        }
        
        for (int p=0; p<contourPoints.size(); p++) {
            circle(matImg, contourPoints[p], 15, Scalar(255,0,0,255), -1);
        }
//        for (int r=0; r<defectPoints.size(); r++) {
//            circle(matImg, defectPoints[r], 15, Scalar(255,255,0,255), -1);
//        }
        
        for (int m=0; m<defects[ci].size(); m++) {
            const Vec4i defect =defects[ci][m];
            Point2i p1(contours[ci][defect[0]]);
            Point2i p2(contours[ci][defect[1]]);
            Point2i p3(contours[ci][defect[2]]);
            float depth = defect[3]/256;
            if (depth > 10){
//                circle(matImg, p1, 10, Scalar(255,0,0,255), -1);
//                circle(matImg, p2, 10, Scalar(0,255,0,255), -1);
                circle(matImg, p3, 10, Scalar(255,255,0,255), -1);
            }
        }
        
        
        
        
        
//            const Vec4i v1 =defects[ci][j-1];
//            const Vec4i v2 =defects[ci][j];
////            float depth1 = v1[3]/256;
////            float depth2 = v1[3]/256;
////            if ( (depth1 > 100) && (depth2 > 100) ) {
//                int v1startIdx = v1[0]; Point2i v1ptStart(contours[ci][v1startIdx]);
//                int v1defectIdx = v1[2]; Point2i v1ptDefect(contours[ci][v1defectIdx]);
//                int v2defectIdx = v2[2]; Point2i v2ptDefect(contours[ci][v2defectIdx]);
//
////                line(matImg, ptStart, ptEnd, Scalar(0,255,0,255), 3);
////                line(matImg, ptDefect, ptEnd, Scalar(0,0,255,255), 3);
////                circle(matImg, ptEnd, 10, Scalar(255,0,0,255), -1);
//
//                line(drawing, v2ptDefect, v1ptStart, Scalar(0,0,255,255), 3);
//                line(drawing, v1ptDefect, v1ptStart, Scalar(0,0,255,255), 3);
//                circle(drawing, v1ptDefect, 10, Scalar(255,0,0,255), -1);
//
//                double a = norm(v1ptDefect - v2ptDefect);
//                double b = norm(v1ptStart - v1ptDefect);
//                double c = norm(v1ptStart - v2ptDefect);
//
//                double calcAngle = acos( (b*b+c*c-a*a)/(2*b*c) ) * (180/3.14);
//                if (calcAngle < maxAngle) {
//                    result = calcAngle;
//                }
////            }
//        }
//
////        putText(drawing, to_string(result), cvPoint(10,200), FONT_HERSHEY_SIMPLEX, 5.0, Scalar(255,255,255,255), 5, CV_AA);
    }

    UIImage *result = MatToUIImage(matImg);
    return result;
}


@end
