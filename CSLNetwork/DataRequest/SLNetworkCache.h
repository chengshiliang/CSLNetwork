//
//  SLNetworkCache.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLNetworkCache : NSObject
+ (instancetype)cacheWithData:(id)data;
+ (instancetype)cacheWithData:(id)data validTimeInterval:(NSUInteger)interterval;
- (id)data;
- (BOOL)isValid;
@end

@interface SLNetworkCacheManager : NSObject
+ (instancetype)sharedManager;
- (void)removeCacheForKey:(NSString *)key;
- (void)setObjcet:(SLNetworkCache *)object forKey:(NSString *)key;
- (SLNetworkCache *)cacheForKey:(NSString *)key;
-(void)addProtectCacheKey:(NSString*)key;// 增加受保护的网络缓存key
@end

NS_ASSUME_NONNULL_END
