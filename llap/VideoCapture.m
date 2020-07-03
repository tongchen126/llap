//
//  VideoCapture.m
//  llap
//
//  Created by chentong on 2020/7/1.
//  Copyright © 2020 Nanjing University. All rights reserved.
//

#import "VideoCapture.h"
#import "VideoCaptureOutputDelegate.h"
@interface VideoCapture()<AVCaptureAudioDataOutputSampleBufferDelegate>
@property (strong, nonatomic) AVCaptureDevice *inputCamera;
@property (strong, nonatomic) AVCaptureDevice *inputMicphone;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;
@property (strong, nonatomic) AVCaptureAudioDataOutput *audioDataOutput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) AVCaptureSessionPreset capturePresent;
@property (strong,nonatomic) AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession;
@end

@implementation VideoCapture
-(instancetype) init{
    if ((self = [super init])){
        dispatch_queue_t videoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
        _delegate = [[VideoCaptureOutputDelegate alloc] init];

        if (@available(iOS 11.1, *)) {
            NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];
            self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        } else {
            // Fallback on earlier versions
            NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera];
            self.videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        }
        
        
        
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession beginConfiguration];
        _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        
        
        
        AVCaptureDevice* videoDevice = nil;
        
        // First, look for a device with both the preferred position and device type.
        /*
        NSArray<AVCaptureDevice* >* devices = _videoDeviceDiscoverySession.devices;
        for (AVCaptureDevice* device in devices) {
            if (device.position == AVCaptureDevicePositionBack && [device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInDualCamera]) {
                videoDevice = device;
                break;
            }
        }
        
        // Otherwise, look for a device with only the preferred position.
        if (!videoDevice) {
            for (AVCaptureDevice* device in devices) {
                if (device.position == AVCaptureDevicePositionBack) {
                    videoDevice = device;
                    break;
                }
            }
        }
        */
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        if (!videoDevice) {
            // If a rear dual camera is not available, default to the rear wide angle camera.
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
            
            // In the event that the rear wide angle camera isn't available, default to the front wide angle camera.
            if (!videoDevice) {
                videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
            }
        }
        if (!videoDevice){
            NSLog(@"Camera not available!");
            return nil;
        }
        _inputCamera = videoDevice;
        /*
         
         */
        NSError *error = nil;
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
        if (error){
            NSLog(@"Camera error");
            return nil;
        }
        if ([_captureSession canAddInput:_videoInput]){
            [_captureSession addInput:_videoInput];
        }
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setAlwaysDiscardsLateVideoFrames:NO]; //是否丢弃旧帧
        [_videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
        [_videoDataOutput setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)self queue:videoQueue];
        if ([_captureSession canAddOutput:_videoDataOutput]){
            [_captureSession addOutput:_videoDataOutput];
        }
        AVCaptureConnection *connection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoStabilizationSupported]){
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        connection.videoScaleAndCropFactor = connection.videoMaxScaleAndCropFactor;
        [_captureSession commitConfiguration];
    }
    return self;
}
-(void) start{

    [_captureSession startRunning];
}
-(void) stop{
    [_captureSession stopRunning];
}
-(void) captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    if (output == _videoDataOutput){
        if (_delegate && [_delegate respondsToSelector:@selector(processVideoSampleBuffer:)]){
            [_delegate processVideoSampleBuffer:sampleBuffer];
        }
    }
}
@end
