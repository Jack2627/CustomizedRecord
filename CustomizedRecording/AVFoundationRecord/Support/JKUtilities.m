//
//  JKUtilities.m
//  AVDemo
//
//  Created by Jack Xue on 2022/7/7.
//

#import "JKUtilities.h"

@implementation JKUtilities

#pragma mark - Public
+ (NSString *)currentTimeString{
    NSDate *date = [NSDate date];
    NSDateFormatter *form = [[NSDateFormatter alloc] init];
    [form setDateFormat:@"yyyyMMddHHmmss"];
//    [form setDateStyle:NSDateFormatterShortStyle];
//    [form setTimeStyle:NSDateFormatterShortStyle];
    NSString *result = [form stringFromDate:date];
    return result;
}

+ (NSString *)supportPath{
    NSString *supportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    return supportPath;
}

+ (NSString *)floderPathInSupportWithFloderName:(NSString *)name{
    if (!name) {
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"%@/%@",[JKUtilities supportPath],name];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isFloder = NO;
    if (![manager fileExistsAtPath:path isDirectory:&isFloder]) {
        NSError *error = nil;
        BOOL creatResult = [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error || !creatResult) {
            return nil;
        }
    }
    return path;
}

@end
