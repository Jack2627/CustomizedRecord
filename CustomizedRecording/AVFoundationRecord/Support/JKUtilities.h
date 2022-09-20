//
//  JKUtilities.h
//  AVDemo
//
//  Created by Jack Xue on 2022/7/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JKUtilities : NSObject
+ (NSString *)currentTimeString;
/**
 获取Application Support路径，返回nil时表示出现错误
 */
+ (nullable NSString *)supportPath;
/**
 获取Application Support下文件夹的路径，将自动创建文件夹，返回nil时表示出现错误
 */
+ (nullable NSString *)floderPathInSupportWithFloderName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
