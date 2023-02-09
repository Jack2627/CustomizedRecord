//
//  AVFTemperatureManager.h
//  CustomizedRecording
//
//  Created by iOS_Developer on 2023/2/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVFTemperatureManager : NSObject
+ (instancetype)manager;
- (nullable NSString *)avf_getWithKey:(NSString *)key;
- (void)avf_setValue:(NSString *)value key:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
