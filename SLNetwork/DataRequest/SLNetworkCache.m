//
//  SLNetworkCache.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/18.
//

#import "SLNetworkCache.h"

@interface SLNetworkCache ()
@property (strong, nonatomic) id data;
@property (nonatomic) NSTimeInterval cacheTime;
@property (nonatomic) NSUInteger validTimeInterval;
@end

@implementation SLNetworkCache
+ (instancetype)cacheWithData:(id)data {
    return [self cacheWithData:data validTimeInterval:60*60];
}

+ (instancetype)cacheWithData:(id)data validTimeInterval:(NSUInteger)interterval {
    SLNetworkCache *cache = [SLNetworkCache new];
    cache.data = data;
    cache.cacheTime = [[NSDate date] timeIntervalSince1970];
    cache.validTimeInterval = interterval > 0 ? interterval : 60*60;
    return cache;
}

- (BOOL)isValid {
    if (self.data) {
        return [[NSDate date] timeIntervalSince1970] - self.cacheTime < self.validTimeInterval;
    }
    return NO;
}
@end

@interface SLCNetworkCacheManager ()

@property (strong, nonatomic) NSCache *cache;

@end

@implementation SLCNetworkCacheManager

+ (instancetype)sharedManager {
    static SLCNetworkCacheManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[super allocWithZone:NULL] init];
        sharedManager.cache = [NSCache new];
        sharedManager.cache.totalCostLimit = 1024 * 1024 * 20;
    });
    return sharedManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedManager];
}

- (void)setObjcet:(SLNetworkCache *)object forKey:(id)key {
    [self.cache setObject:object forKey:key];
}

- (void)removeObejectForKey:(id)key {
    [self.cache removeObjectForKey:key];
}

- (SLNetworkCache *)objcetForKey:(id)key {
    return [self.cache objectForKey:key];
}

@end
