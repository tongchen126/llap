//
//  ViewController.m
//  llap
//
//  Created by Ke Sun on 5/18/17.
//  Copyright © 2016 Nanjing University. All rights reserved.
//

#import "ViewController.h"
#import "AudioController.h"
#import "AppDelegate.h"
#import "VideoCaptureV2.h"

@interface ViewController (){
    AudioController *audioController;
    VideoCaptureV2 *videoCapture;
    NSString *_reslut;
    BOOL _isTakeTime;
    NSInteger _timeIndex; //计数器
}

@property (weak, nonatomic) IBOutlet UISlider *slider;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _reslut = @"";
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performDisUpdate:) name:@"AudioDisUpdate" object:nil];
    [_slider setValue: 0.0];
    [self.view addSubview: _slider];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeChange) userInfo:nil repeats:YES];


     [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];


}
- (void)timeChange{
    _timeIndex ++;
    if (_timeIndex == 10) {
        _isTakeTime = YES;
        _timeIndex = 0;
    }else{
        _isTakeTime = NO;
    }
}
/*
- (IBAction)playbutton:(UIButton *)sender {
    if (audioController){
        [audioController stopIOUnit];
        audioController = nil;
    }
    audioController = [[AudioController alloc] init];
    if (videoCapture){
        [videoCapture stop];
        videoCapture = nil;
    }
    videoCapture = [[VideoCapture alloc] init];
    audioController.audiodistance=0;
    [audioController startIOUnit];
    [videoCapture start];
}
- (IBAction)stopbutton:(UIButton *)sender {
    if (videoCapture){
        [videoCapture stop];
        videoCapture = nil;
    }
    if (audioController){
        [audioController stopIOUnit];
    }
}
*/

- (IBAction)playbutton:(UIButton *)sender {
    if (audioController){
        [audioController stopIOUnit];
        audioController = nil;
    }
    audioController = [[AudioController alloc] init];
    
    videoCapture = [[VideoCaptureV2 alloc] init];
    audioController.audiodistance=0;
    [audioController startIOUnit];
    [videoCapture start];
}
- (IBAction)stopbutton:(UIButton *)sender {
    if (videoCapture){
        [videoCapture stop];
        videoCapture = nil;
    }
    if (audioController){
        [audioController stopIOUnit];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)performDisUpdate:(NSNotification *)notification
{
    if (audioController){
        dispatch_async(dispatch_get_main_queue(), ^{
            
            int tempdis=(int) audioController.audiodistance/DISPLAY_SCALE;
        
            _slider.value=(audioController.audiodistance-DISPLAY_SCALE*tempdis)/DISPLAY_SCALE;
        
            NSLog(@"********%lf",audioController.audiodistance);
            [self saveContentWithDistance:[NSString stringWithFormat:@"%lf",audioController.distanceChange]];
        });
    }

}

- (void)saveContentWithDistance:(NSString *)distance{
    
     AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
       NSString *path = delegate.path;

       //这个是准备存放字符串的文件的路径

          NSError *error;
       _reslut = [_reslut stringByAppendingString:[NSString stringWithFormat:@"%@ ",distance]];

    if (_isTakeTime) {
        _isTakeTime = false;
        _reslut = [_reslut stringByAppendingString:[NSString stringWithFormat:@"\n时间戳：%@\n",[self getNowTimeTimestamp]]];
    }
       
    [_reslut writeToFile:delegate.path atomically:YES encoding:NSUTF8StringEncoding error:&error];

          if (error) {

              NSLog(@"文件写入失败!");

           }else{

              NSLog(@"文件写入成功!");

           }
    
}

- (NSString *)getNowTimeTimestamp{

    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //24小时制：yyyy-MM-dd HH:mm:ss  12小时制：yyyy-MM-dd hh:mm:ss
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.sss";
    NSString *nowDateString = [dateFormatter stringFromDate:date];

    return nowDateString;

}
@end
