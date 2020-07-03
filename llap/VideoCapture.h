//
//  VideoCapture.h
//  llap
//
//  Created by chentong on 2020/7/1.
//  Copyright © 2020 Nanjing University. All rights reserved.
//
#ifndef VideoCapture_h
#define VideoCapture_h
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@protocol CaptureSessionDelegate <NSObject>
- (void) processVideoSampleBuffer:(CMSampleBufferRef) sampleBuffer;

@end

@interface VideoCapture : NSObject

@property (strong, nonatomic) id<CaptureSessionDelegate> delegate;
@property (strong, nonatomic) AVCaptureSession *captureSession;
-(instancetype) init;
-(void) start;
-(void) stop;
@end
#endif /* VideoCapture_h */
