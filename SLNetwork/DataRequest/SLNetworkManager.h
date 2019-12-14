//
//  SLNetworkManager.h
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLRequestDataProtocol.h>
#import <AFNetworking/AFHTTPSessionManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLNetworkManager : NSObject
@property (nonatomic, copy) NSDictionary<NSNumber *, NSURLSessionTask *> *taskIds;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
+ (instancetype)share;
- (void)requestWithModel:(id<SLRequestDataProtocol>)model;
@end

NS_ASSUME_NONNULL_END
