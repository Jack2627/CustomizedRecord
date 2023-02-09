//
//  AVFTemperatureManager.m
//  CustomizedRecording
//
//  Created by iOS_Developer on 2023/2/9.
//

#import "AVFTemperatureManager.h"

@implementation AVFTemperatureManager{
    NSMutableDictionary *_dict;
}

+ (instancetype)manager{
    static AVFTemperatureManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[AVFTemperatureManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Public
- (NSString *)avf_getWithKey:(NSString *)key{
    if (!key || ![key isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *str = [_dict objectForKey:key];
    if (str && [str isKindOfClass:[NSString class]]) {
        return str;
    }
    return nil;
}

- (void)avf_setValue:(NSString *)value key:(NSString *)key{
    if (!value || ![value isKindOfClass:[NSString class]]) {
        return;
    }
    
    if (!key || ![key isKindOfClass:[NSString class]]) {
        return;
    }
    
    [_dict setObject:value forKey:key];
}

@end
