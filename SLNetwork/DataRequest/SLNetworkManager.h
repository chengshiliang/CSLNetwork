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
typedef void(^SLNetworkCompletionHandle)(NSURLResponse *response,id responseObject,NSError *error);

@interface SLNetworkManager : NSObject
@property (nonatomic, copy) NSDictionary<NSNumber *, NSURLSessionTask *> *requestTasks;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
+ (instancetype)share;
- (void)requestWithModel:(id<SLRequestDataProtocol>)model
       completionHandler:(SLNetworkCompletionHandle)completionHandle;
- (void)requestWithModel:(id<SLRequestDataProtocol>)model
          uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
       completionHandler:(SLNetworkCompletionHandle)completionHandle;
- (void)cancelAllTask;
- (void)cancelTaskWithModel:(id<SLRequestDataProtocol>)model;
@end

NS_ASSUME_NONNULL_END
