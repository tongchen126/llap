//
//  StringLogging.m
//  llap
//
//  Created by chentong on 2020/7/8.
//  Copyright © 2020 Nanjing University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StringLogging.h"
@interface StringLogging()
@property NSFileHandle *fileHandler;
@end
@implementation StringLogging
-(void) setPath:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]){
        BOOL ret = [fileManager removeItemAtPath:filePath error:nil];
        if (ret)
            NSLog(@"setPath: File removed");
        else
            NSLog(@"setPath: File not exists");
    }
    [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    _fileHandler = [NSFileHandle fileHandleForWritingAtPath:filePath];
}
-(BOOL) writeString: (NSString *)_data{
    NSData *data = [_data dataUsingEncoding:NSUTF8StringEncoding];
    if (_fileHandler){
        [_fileHandler seekToEndOfFile];
        [_fileHandler writeData:data];
        return TRUE;
    }
    return FALSE;
}
-(void) close{
    if (_fileHandler)
        [_fileHandler closeFile];
}
@end
