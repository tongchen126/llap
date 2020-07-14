//
//  TimeInfo.h
//  llap
//
//  Created by chentong on 2020/7/8.
//  Copyright © 2020 Nanjing University. All rights reserved.
//

#ifndef TimeInfo_h
#define TimeInfo_h
#import <Foundation/Foundation.h>
@interface TimeInfo :NSObject
+(NSString *) getMillSecond;
+(NSString *) getSecond;
+(NSString *) getMillSecondNoEnd;
@end
#endif /* TimeInfo_h */
