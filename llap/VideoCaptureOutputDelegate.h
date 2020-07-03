//
//  VideoCaptureOutputDelegate.h
//  llap
//
//  Created by chentong on 2020/7/2.
//  Copyright © 2020年 Nanjing University. All rights reserved.
//

#ifndef VideoCaptureOutputDelegate_h
#define VideoCaptureOutputDelegate_h
#import "VideoCapture.h"
@interface VideoCaptureOutputDelegate : NSObject <CaptureSessionDelegate>
- (void) processVideoSampleBuffer:(CMSampleBufferRef) sampleBuffer;
- (void) stop;
@end

#endif /* VideoCaptureOutputDelegate_h */
