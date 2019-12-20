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
@property (nonatomic, copy) BOOL(^responseBlock)(NSURLResponse *response,id responseObject,NSError *error);
@property (nonatomic, copy) NSString *baseUrl;
@property (nonatomic, assign) long long diskCacheSize;
- (void)addCommonRequestHeaderWithKey:(NSString *)key value:(id)value;
- (void)removeCommonRequestHeaderKey:(NSString *)key;
- (void)addCommonRequestHeaderWithParams:(NSDictionary *)params;
- (NSDictionary *)commonHeader;

- (BOOL)handleResponseDataWithReponse:(NSURLResponse *)response
                       responseObject:(id)responseObject
                                error:(NSError *)error;// 是否成功拦截网络请求返回数据。不需要下一步处理。比如401直接登陆的情况
//- (void)addCookie:(NSHttpCookie)
@end

NS_ASSUME_NONNULL_END
