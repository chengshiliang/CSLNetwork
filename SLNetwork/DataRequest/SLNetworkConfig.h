//
//  SLNetworkConfig.h
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLNetworkConfig : NSObject
+ (instancetype)share;
- (void)setBaseUrl:(NSString *)baseUrl;
- (NSString *)baseUrl;
- (void)addCommonRequestHeaderWithKey:(NSString *)key value:(id)value;
- (void)addCommonRequestHeaderWithParams:(NSDictionary *)params;
- (NSDictionary *)commonHeader;
//- (void)addCookie:(NSHttpCookie)
@end

NS_ASSUME_NONNULL_END
