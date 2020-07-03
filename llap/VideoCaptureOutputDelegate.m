//
//  VideoCaptureOutputDelegate.m
//  llap
//
//  Created by chentong on 2020/7/2.
//  Copyright © 2020年 Nanjing University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VideoCaptureOutputDelegate.h"
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface VideoCaptureOutputDelegate()
@property (strong,nonatomic) AVAssetWriter *assetWriter;
@property (strong,nonatomic) AVAssetWriterInput *assetWriterVideoInput;
@property (strong,nonatomic) NSURL *videoURL;
@property BOOL firstRecord;
@end
@implementation VideoCaptureOutputDelegate
- (instancetype) init{
    self = [super init];
    if (self){
        NSError *error;
        _videoURL = [NSURL fileURLWithPath:[self createVideoFilePath]];
        _assetWriter = [AVAssetWriter assetWriterWithURL:_videoURL fileType:AVFileTypeMPEG4 error:&error];
        if (error){
            NSLog(@"AVAssetWriter alloc failed");
            return nil;
        }
        _firstRecord = true;
    }
    return self;
}
- (void) processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (_firstRecord){
        /*
        CMVideoFormatDescriptionRef desc = CMSampleBufferGetFormatDescription(sampleBuffer);
        CMVideoDimensions dim = CMVideoFormatDescriptionGetDimensions(desc);
        int width = dim.width, height = dim.height;
        NSInteger numPixels = kScreenWidth * kScreenHeight;
        
        
        //每像素比特
        CGFloat bitsPerPixel = 12.0;
        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
        
        // 码率和帧率设置
        NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                                 AVVideoExpectedSourceFrameRateKey : @(15),
                                                 AVVideoMaxKeyFrameIntervalKey : @(15),
                                                 AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
        width = kScreenHeight;
        height = kScreenWidth;
        //视频属性
      NSDictionary *videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                                    AVVideoWidthKey : @(width * 2),
                                                    AVVideoHeightKey : @(height * 2),
                                                    AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                                    AVVideoCompressionPropertiesKey : compressionProperties };
         flag
    */
        
        
        
        
        NSDictionary *videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264};
        _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings sourceFormatHint:CMSampleBufferGetFormatDescription(sampleBuffer)];
        //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
        _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_assetWriterVideoInput]){
            [_assetWriter addInput:_assetWriterVideoInput];
        }
        [_assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        _firstRecord = false;
        
    }
    if ([_assetWriterVideoInput isReadyForMoreMediaData]){
        BOOL success = [_assetWriterVideoInput appendSampleBuffer:sampleBuffer];
        if (!success){
            NSLog(@"assetWriter write failed");
        }
    }
}

- (NSString *)createVideoFilePath
{
    // 创建视频文件的存储路径
    NSString *filePath = [self createVideoFolderPath];
    if (filePath == nil)
    {
        return nil;
    }
    
    NSString *videoType = @".mp4";
    NSString *videoDestDateString = [self createFileNamePrefix];
    NSString *videoFileName = [videoDestDateString stringByAppendingString:videoType];
    
    NSUInteger idx = 1;
    /*We only allow 10000 same file name*/
    NSString *finalPath = [NSString stringWithFormat:@"%@/%@", filePath, videoFileName];
    
    while (idx % 10000 && [[NSFileManager defaultManager] fileExistsAtPath:finalPath])
    {
        finalPath = [NSString stringWithFormat:@"%@/%@_(%lu)%@", filePath, videoDestDateString, (unsigned long)idx++, videoType];
    }
    
    return finalPath;
}

- (NSString *)createVideoFolderPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *homePath = NSHomeDirectory();
    
    NSString *tmpFilePath;
    
    if (homePath.length > 0)
    {
        NSString *documentPath = [homePath stringByAppendingString:@"/Documents"];
        if ([fileManager fileExistsAtPath:documentPath isDirectory:NULL] == YES)
        {
            BOOL success = NO;
            
            NSArray *paths = [fileManager contentsOfDirectoryAtPath:documentPath error:nil];
            
            //offline file folder
            tmpFilePath = [documentPath stringByAppendingString:[NSString stringWithFormat:@"/%@", @"video"]];
            if ([paths containsObject:@"video"] == NO)
            {
                success = [fileManager createDirectoryAtPath:tmpFilePath withIntermediateDirectories:YES attributes:nil error:nil];
                if (!success)
                {
                    tmpFilePath = nil;
                }
            }
            return tmpFilePath;
        }
    }
    
    return false;
}

/**
 *  创建文件名
 */
- (NSString *)createFileNamePrefix
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    
    NSString *destDateString = [dateFormatter stringFromDate:[NSDate date]];
    destDateString = [destDateString stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    destDateString = [destDateString stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    destDateString = [destDateString stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    
    return destDateString;
}
@end
