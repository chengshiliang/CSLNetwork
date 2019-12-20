//
//  SLChainRequestManager.m
//  AFNetworking
//
//  Created by SZDT00135 on 2019/12/20.
//

#import "SLChainRequestManager.h"
#import <SLNetwork/SLNetworkManager.h>

@interface SLChainRequestModel : NSObject
@property (nonatomic, strong) id<SLRequestDataProtocol> model;
@property (nonatomic, copy) void(^uploadProgressBlock)(NSProgress *uploadProgress);
@property (nonatomic, copy) void(^completionHandle)(NSURLResponse *response,id responseObject,NSError *error);
@end

@implementation SLChainRequestModel

@end

@interface SLChainRequestManager()
@property (nonatomic, strong) NSMutableArray *chainRequests;
@end

@implementation SLChainRequestManager
- (instancetype)init {
    if (self == [super init]) {
        self.chainRequests = [NSMutableArray array];
    }
    return self;
}

- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    [self addRequestWithModel:model
               uploadProgress:nil
            completionHandler:completionHandle];
}

- (void)addRequestWithModel:(id<SLRequestDataProtocol>)model
             uploadProgress:(void(^)(NSProgress *uploadProgress))uploadProgressBlock
          completionHandler:(void(^)(NSURLResponse *response,id responseObject,NSError *error))completionHandle {
    if (!model || ![model conformsToProtocol:@protocol(SLRequestDataProtocol)]) return;
    SLChainRequestModel *requestModel = [SLChainRequestModel new];
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
    SLChainRequestModel *requestModel = self.chainRequests[0];
    __weak typeof (self)weakSelf = self;
    [[SLNetworkManager share]requestWithModel:requestModel.model uploadProgress:requestModel.uploadProgressBlock completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error) {
        __strong typeof (weakSelf)strongSelf = weakSelf;
        !requestModel.completionHandle ?: requestModel.completionHandle(response, responseObject, error);
        [strongSelf.chainRequests removeObject:requestModel];
        [strongSelf startRequest:completeBlock];
    }];
}

@end
