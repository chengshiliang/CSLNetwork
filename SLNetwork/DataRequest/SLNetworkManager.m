//
//  SLNetworkManager.m
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLNetworkManager.h"
#import <SLNetwork/SLRequestSerialization.h>
#import <SLNetwork/SLNetworkTool.h>
#import <SLNetwork/SLNetworkConfig.h>


@interface SLNetworkManager()
@property (nonatomic, assign) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) SLRequestSerialization *requestSerialization;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLSessionTask *> *requestInfo;
@end

@implementation SLNetworkManager
static SLNetworkManager *sharedInstance;
+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        sharedInstance.semaphore = dispatch_semaphore_create(1);
        sharedInstance.requestSerialization = [[SLRequestSerialization alloc]init];
    });
    return sharedInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self share];
}
- (instancetype)init {
    if (self = [super init]) {
        self.requestInfo = [NSMutableDictionary dictionary];
        self.sessionManager = [AFHTTPSessionManager manager];
        self.sessionManager.securityPolicy.validatesDomainName = NO;
        self.sessionManager.securityPolicy.allowInvalidCertificates = YES;
        self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        NSMutableSet *acceptableContentTypes = [NSMutableSet setWithSet:self.sessionManager.responseSerializer.acceptableContentTypes];
        [acceptableContentTypes addObject:@"text/html"];
        [acceptableContentTypes addObject:@"text/plain"];
        self.sessionManager.responseSerializer.acceptableContentTypes = [acceptableContentTypes copy];
    }
    return self;
}

- (void)requestWithModel:(id<SLRequestDataProtocol>)model
       completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    [self requestWithModel:model uploadProgress:nil completionHandler:completionHandle];
}

- (void)requestWithModel:(id<SLRequestDataProtocol>)model
          uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
       completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    NSMutableURLRequest *request = [sharedInstance.requestSerialization generateRequestWithModel:model];
    if (!request) return;
    __weak typeof (self)weakSelf = self;
    NSURLSessionDataTask *task;
    if ([SLNetworkTool isUploadRequest:[model uploadFiles]]) {
        task = [self.sessionManager uploadTaskWithStreamedRequest:request
                                                         progress:uploadProgressBlock
                                                completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            __strong typeof (weakSelf)strongSelf = weakSelf;
            [strongSelf handleReponseResultWithModel:model
                                             reponse:response
                                      responseObject:responseObject
                                               error:error
                                   completionHandler:completionHandle];
        }];
    } else {
        task = [self.sessionManager dataTaskWithRequest:request
                                         uploadProgress:nil
                                       downloadProgress:nil
                                      completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            __strong typeof (weakSelf)strongSelf = weakSelf;
            [strongSelf handleReponseResultWithModel:model
                                             reponse:response
                                      responseObject:responseObject
                                               error:error
                                   completionHandler:completionHandle];
        }];
    }
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [self.requestInfo setObject:task forKey:[model description]];
    dispatch_semaphore_signal(sharedInstance.semaphore);
    [task resume];
}

- (void)handleReponseResultWithModel:(id<SLRequestDataProtocol>)model
                             reponse:(NSURLResponse *)response
                      responseObject:(id)responseObject
                               error:(NSError *)error
                   completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [self.requestInfo removeObjectForKey:[model description]];
    dispatch_semaphore_signal(sharedInstance.semaphore);
    if ([[SLNetworkConfig share]handleResponseDataWithReponse:response
                                               responseObject:responseObject
                                                        error:error]) return;
    !completionHandle ?: completionHandle(response, responseObject, error);
}

- (void)cancelAllTask {
    for (NSURLSessionTask *task in self.requestInfo.allValues) {
        [task cancel];
    }
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    [self.requestInfo removeAllObjects];
    dispatch_semaphore_signal(sharedInstance.semaphore);
}

- (void)cancelTaskWithModel:(id<SLRequestDataProtocol>)model {
    NSString *key = [model description];
    if ([SLNetworkTool sl_networkEmptyString:key]) return;
    NSURLSessionTask *task = self.requestInfo[key];
    if (task) [task cancel];
    dispatch_semaphore_wait(sharedInstance.semaphore, DISPATCH_TIME_FOREVER);
    if ([self.requestInfo.allKeys containsObject:key]) {
        [self.requestInfo removeObjectForKey:key];
    }
    dispatch_semaphore_signal(sharedInstance.semaphore);
}

- (NSDictionary<NSNumber *,NSURLSessionTask *> *)requestTasks {
    return [self.requestInfo copy];
}
@end
