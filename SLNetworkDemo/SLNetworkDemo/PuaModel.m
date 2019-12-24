//
//  PuaModel.m
//  SLNetworkDemo
//
//  Created by SZDT00135 on 2019/12/23.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "PuaModel.h"
@implementation PuaList
- (SLRequestMethod)requestMethod {
    return SLRequestGet;
}
- (NSTimeInterval)cacheTimeInterval {
    return 24*60*60;
}
- (NSString *)requestUrl {
    return @"puas";
}
@end
@implementation PuaHandle
- (SLRequestMethod)requestMethod {
    return SLRequestPatch;
}
- (NSString *)requestUrl {
    return @"pua/1157193/state";
}
@end
@implementation PuaPermissionModify
- (SLRequestMethod)requestMethod {
    return SLRequestPost;
}
- (NSString *)requestUrl {
    return @"permission/1157193";
}
@end
@implementation PuaAudit
- (SLRequestMethod)requestMethod {
    return SLRequestPost;
}
- (NSString *)requestUrl {
    return @"entity_ca/134/audits";
}
@end
@implementation PuaModel

@end
