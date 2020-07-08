//
//  StringLogging.h
//  llap
//
//  Created by chentong on 2020/7/8.
//  Copyright © 2020 Nanjing University. All rights reserved.
//

#ifndef StringLogging_h
#define StringLogging_h
#import <Foundation/Foundation.h>
@interface StringLogging : NSObject
-(void) setPath: (NSString *)filePath;
-(BOOL) writeString:(NSString *)data;
-(void) close;
@end
#endif /* StringLogging_h */
