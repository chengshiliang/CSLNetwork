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

@interface SLCNetworkCacheManager : NSObject
+ (instancetype)sharedManager;
- (void)removeObejectForKey:(id)key;
- (void)setObjcet:(SLNetworkCache *)object forKey:(id)key;
- (SLNetworkCache *)objcetForKey:(id)key;
@end

NS_ASSUME_NONNULL_END
