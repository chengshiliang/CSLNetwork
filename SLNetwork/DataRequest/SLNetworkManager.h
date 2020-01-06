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
@property (nonatomic, copy) NSDictionary<NSNumber *, NSURLSessionTask *> *requestTasks;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
+ (instancetype)share;
- (NSNumber *)requestWithModel:(id<SLRequestDataProtocol>)model
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle;
- (NSNumber *)requestWithModel:(id<SLRequestDataProtocol>)model
                uploadProgress:(void(^_Nullable)(NSProgress *uploadProgress))uploadProgressBlock
             completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle;
- (void)cancelAllTask;
- (void)cancelTaskWithtaskIdentifier:(NSNumber *)taskIdentifierl;
@end

NS_ASSUME_NONNULL_END
