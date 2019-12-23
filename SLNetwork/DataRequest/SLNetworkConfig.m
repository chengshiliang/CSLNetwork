//
//  SLNetworkConfig.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLNetworkConfig.h"
#import <SLNetwork/SLNetworkTool.h>

@interface SLNetworkConfig()
@property (nonatomic, strong) NSMutableDictionary *commonHeaders;
@end

@implementation SLNetworkConfig
static SLNetworkConfig *sharedInstance;
+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.commonHeaders = [NSMutableDictionary dictionary];
    });
    return sharedInstance;
}
- (void)addCommonRequestHeaderWithKey:(NSString *)key value:(id)value {
    if ([SLNetworkTool sl_networkEmptyString:key]) return;
    if (!value) return;
    [sharedInstance.commonHeaders setValue:value forKey:key];
}
- (void)removeCommonRequestHeaderKey:(NSString *)key {
    if ([SLNetworkTool sl_networkEmptyString:key]) return;
    [sharedInstance.commonHeaders removeObjectForKey:key];
}
- (void)addCommonRequestHeaderWithParams:(NSDictionary *)params {
    if (!params) return;
    [sharedInstance.commonHeaders addEntriesFromDictionary:params];
}
- (NSDictionary *)commonHeader {
    return [self.commonHeaders copy];
}
- (BOOL)handleResponseDataWithReponse:(NSURLResponse *)response
                       responseObject:(id)responseObject
                                error:(NSError *)error {
    if (self.responseBlock) {
        return sharedInstance.responseBlock(response, responseObject, error);
    }
    return NO;
}
@end
