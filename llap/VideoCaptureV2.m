//
//  VideoCaptureV2.m
//  llap
//
//  Created by chentong on 2020/7/14.
//  Copyright © 2020 Nanjing University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "StringLogging.h"
#import "TimeInfo.h"
#import "VideoCaptureV2.h"
typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define DISCARD_FRAMES_NUM 60
@interface VideoCaptureV2() <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;      //预览图层
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic,strong) NSURL *videoURL;
@property BOOL recording;
@property BOOL canWrite;
@property BOOL writerinited;
@property int frames;
@property StringLogging *timeLogging;
@end
@implementation VideoCaptureV2
- (AVCaptureSession *)captureSession
{
    if (_captureSession == nil)
    {
        _captureSession = [[AVCaptureSession alloc] init];
        
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
        {
            _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    
    return _captureSession;
}
- (dispatch_queue_t)videoQueue
{
    if (!_videoQueue)
    {
        _videoQueue = dispatch_queue_create("XFCameraController", DISPATCH_QUEUE_SERIAL); // dispatch_get_main_queue();
    }
    
    return _videoQueue;
}
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras)
    {
        if ([camera position] == position)
        {
            return camera;
        }
    }
    return nil;
}
- (void)startSession
{
    if (![self.captureSession isRunning])
    {
        [self.captureSession startRunning];
    }
}
- (void)selectFormat{
    AVCaptureDevice *videoDevice = _captureDevice;
     AVCaptureDeviceFormat *selectedFormat = nil;
     AVFrameRateRange *selectedRange = nil;
     for (AVCaptureDeviceFormat *format in [videoDevice formats]){
         for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges){
             CMFormatDescriptionRef desc = format.formatDescription;
             CMVideoDimensions dimesions = CMVideoFormatDescriptionGetDimensions(desc);
             NSLog(@"%f:%f",range.minFrameRate,range.maxFrameRate);
             NSLog(@"%d*%d",dimesions.width,dimesions.height);
       /*      if (dimesions.width==1920 && dimesions.height==1080 && range.minFrameRate==6 && range.maxFrameRate==60){
                 selectedFormat = selectedFormat;
             }
        */
             if (dimesions.width==1920 && dimesions.height==1080 && range.maxFrameRate==60){
                 selectedFormat = format;
                 selectedRange = range;
                 break;
             }
         }
         if (selectedRange)
             break;
     }
    [self changeDeviceProperty:^(AVCaptureDevice *videoDevice){
        if (selectedFormat){
             [videoDevice setActiveFormat:selectedFormat];
             videoDevice.activeVideoMinFrameDuration = selectedRange.minFrameDuration;
             videoDevice.activeVideoMaxFrameDuration = selectedRange.maxFrameDuration;
         }
        
         CGPoint point = CGPointMake(0.5, 0.5);
         if ([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
             [videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
         }
         if ([videoDevice isFocusPointOfInterestSupported])
         {
             [videoDevice setFocusPointOfInterest:point];
         }
         if ([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
             [videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
         }
         if ([videoDevice isExposurePointOfInterestSupported])
         {
             [videoDevice setExposurePointOfInterest:point];
         }
         
    }];
}
- (void)setup {
    _captureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];
    NSError *error = nil;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
    if ([self.captureSession canAddInput:self.videoInput])
    {
        [self.captureSession addInput:self.videoInput];
    }
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.captureSession canAddOutput:self.videoOutput])
    {
        [self.captureSession addOutput:self.videoOutput];
    }
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
 //   [self selectFormat];
    [self startSession];
    _recording = FALSE;
}
- (void)changeDeviceProperty:(PropertyChangeBlock)propertyChange
{
    AVCaptureDevice *captureDevice = [self.videoInput device];
    NSError *error;
    
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error])
    {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }
    else
    {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}
-(void) setupWriter{
    _videoURL = [NSURL fileURLWithPath:[self getVideoFilePath]];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:_videoURL fileType:AVFileTypeMPEG4 error:nil];
       //写入视频大小
    /*
       NSInteger numPixels = kScreenWidth * kScreenHeight;
       
       //每像素比特
       CGFloat bitsPerPixel = 12.0;
       NSInteger bitsPerSecond = numPixels * bitsPerPixel;
       
       // 码率和帧率设置
       NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                                AVVideoExpectedSourceFrameRateKey : @(60),
                                                AVVideoMaxKeyFrameIntervalKey : @(60),
                                                AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
       CGFloat width = kScreenHeight;
       CGFloat height = kScreenWidth;
    */
       //视频属性
     /*  self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                          AVVideoWidthKey : @(width * 2),
                                          AVVideoHeightKey : @(height * 2),
                                          AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                          AVVideoCompressionPropertiesKey : compressionProperties };
  */
 
        self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecTypeH264,
                                                 AVVideoWidthKey : @1920,
                                                 AVVideoHeightKey : @1080,
                                                 AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                           
        };
      
       _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
       //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
       _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
       _assetWriterVideoInput.transform = CGAffineTransformMakeRotation(0);
        if ([_assetWriter canAddInput:_assetWriterVideoInput])
        {
            [_assetWriter addInput:_assetWriterVideoInput];
        }
    _timeLogging = [[StringLogging alloc] init];
    _writerinited = TRUE;
}
-(instancetype) init{
    self = [super init];
    if (self)
        [self setup];
    return self;
}
-(void) start{
    _recording = TRUE;
    _canWrite = FALSE;
    _writerinited = FALSE;
    _frames = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupWriter];
    });
}
-(void) stop{
    if (_recording){
        _recording = FALSE;
        __weak __typeof(self)weakSelf = self;
        [_timeLogging close];
        if (_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
            [_assetWriter finishWritingWithCompletionHandler:^{
                AVAssetWriterStatus status = _assetWriter.status;
                weakSelf.canWrite = NO;
                weakSelf.frames = 0;
                weakSelf.assetWriter = nil;
                weakSelf.assetWriterVideoInput = nil;
                weakSelf.timeLogging = nil;
                if (status == AVAssetWriterStatusCompleted) {
                    NSString *file = _videoURL.path;
                    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
                        //保存相册核心代码
                        UISaveVideoAtPathToSavedPhotosAlbum(file, self, nil, nil);
                    }
                    NSLog(@"finsished");
                    
                }
            }];
        }
    }
}
- (NSString *)getLogFilePath{
    NSString *storageFolder = [self storageFolderPath];
    NSString *logPath = [NSString stringWithFormat:@"%@/%@", storageFolder, @"timelog.txt"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:logPath]){
        [fileMgr removeItemAtPath:logPath error:nil];
    }
    return logPath;
}
- (NSString *)getVideoFilePath{
    NSString *storageFolder = [self storageFolderPath];
    NSString *videoPath = [NSString stringWithFormat:@"%@/%@", storageFolder, @"record.mp4"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:videoPath]){
        [fileMgr removeItemAtPath:videoPath error:nil];
    }
    return videoPath;
}
- (NSString *) storageFolderPath {
    NSString *homePath = NSHomeDirectory();
    NSString *documentPath = [homePath stringByAppendingPathComponent:@"/Documents"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (NO == [fileMgr fileExistsAtPath:documentPath])
        [fileMgr createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    return documentPath;
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool
    {
        //视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo])
        {
            @synchronized(self)
            {
                if (_recording)
                {
                    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                }
            }
        }
    }
}
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if (sampleBuffer == NULL)
    {
        NSLog(@"empty sampleBuffer");
        return;
    }
    if (!_writerinited){
        NSLog(@"Writer init not finished");
        return;
    }
        @autoreleasepool
        {
            if (_frames < DISCARD_FRAMES_NUM){
                _frames+=1;
                return;
            }
            if (!self.canWrite && mediaType == AVMediaTypeVideo)
            {
                [self.assetWriter startWriting];
                [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                self.canWrite = YES;
            }
            //写入视频数据
            if (mediaType == AVMediaTypeVideo)
            {
                if (self.assetWriterVideoInput.readyForMoreMediaData)
                {
                    BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    [_timeLogging writeString:[TimeInfo getMillSecond]];
                    if (!success)
                    {
                        NSLog(@"Write Video Failed");
                    }
                }
            }
        }
}

@end
