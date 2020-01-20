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
@property (nonatomic, copy) BOOL(^requestBeforeBlock)(NSMutableURLRequest *request);
@property (nonatomic, copy) NSString *baseUrl;
@property (nonatomic, assign) NSTimeInterval requestTimeoutInteval;
@property (nonatomic, assign) long long diskCacheSize;
- (void)addCommonRequestHeaderWithKey:(NSString *)key value:(id)value;
- (void)removeCommonRequestHeaderKey:(NSString *)key;
- (void)addCommonRequestHeaderWithParams:(NSDictionary *)params;
- (NSDictionary *)commonHeader;

- (BOOL)handleResponseDataWithReponse:(NSURLResponse * _Nullable)response
                       responseObject:(id _Nullable)responseObject
                                error:(NSError * _Nullable)error;// 是否成功拦截网络请求返回数据。不需要下一步处理。比如401直接登陆的情况
- (BOOL)handleRequest:(NSMutableURLRequest * _Nullable)request;// 请求前的统一拦截处理, 类似NSURLProtocol
@end

NS_ASSUME_NONNULL_END
