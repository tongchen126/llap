//
//  TimeInfo.m
//  llap
//
//  Created by chentong on 2020/7/8.
//  Copyright © 2020 Nanjing University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimeInfo.h"
@implementation TimeInfo
+(NSString *)getMillSecond{
    NSString* date;
    NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
    //[formatter setDateFormat:@"YYYY.MM.dd.hh.mm.ss"];
    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSS"];
    date = [NSString stringWithFormat:@"%@\n",[formatter stringFromDate:[NSDate date]]];
    return date;
}
@end
