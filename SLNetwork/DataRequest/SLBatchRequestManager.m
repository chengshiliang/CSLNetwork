//
//  SLBatchRequestManager.m
//  AFNetworking
//
//  Created by SZDT00135 on 2019/12/20.
//

#import "SLBatchRequestManager.h"
#import <SLNetwork/SLNetworkManager.h>

@interface SLBatchRequestModel : NSObject
@property (nonatomic, strong) id<SLRequestDataProtocol> model;
@property (nonatomic, copy) void(^uploadProgressBlock)(NSProgress *uploadProgress);
@property (nonatomic, copy) void(^completionHandle)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle);
@end

@implementation SLBatchRequestModel

@end

@interface SLBatchRequestManager()
@property (nonatomic, strong) NSMutableArray *chainRequests;
@end

@implementation SLBatchRequestManager
- (instancetype)init {
    if (self == [super init]) {
        self.chainRequests = [NSMutableArray array];
    }
    return self;
}

- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle {
    [self addRequestWithModel:model
               uploadProgress:nil
            completionHandler:completionHandle];
}

- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
             uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error, BOOL needHandle))completionHandle {
    if (!model || ![model conformsToProtocol:@protocol(SLRequestDataProtocol)]) return;
    SLBatchRequestModel *requestModel = [SLBatchRequestModel new];
    requestModel.model = model;
    requestModel.uploadProgressBlock = [uploadProgressBlock copy];
    requestModel.completionHandle = [completionHandle copy];
    [self.chainRequests addObject:requestModel];
}

- (void)startRequest:(void(^)())completeBlock {
    if (self.chainRequests.count <= 0) {
        !completeBlock?:completeBlock();
        return;
    }
    SLBatchRequestModel *requestModel = self.chainRequests[0];
    __weak typeof (self)weakSelf = self;
    [[SLNetworkManager share]requestWithModel:requestModel.model uploadProgress:requestModel.uploadProgressBlock completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error, BOOL needHandle) {
        __strong typeof (weakSelf)strongSelf = weakSelf;
        !requestModel.completionHandle ?: requestModel.completionHandle(response, responseObject, error, needHandle);
        [strongSelf.chainRequests removeObject:requestModel];
        [strongSelf startRequest:completeBlock];
    }];
}

@end
