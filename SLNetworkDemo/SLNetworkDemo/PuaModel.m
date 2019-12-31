//
//  PuaModel.m
//  SLNetworkDemo
//
//  Created by SZDT00135 on 2019/12/23.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "PuaModel.h"
@implementation PuaUpload
- (SLRequestMethod)requestMethod {
    return SLRequestPost;
}
- (NSString *)requestUrl {
    return @"upload/private";
}
- (NSString *)requestBaseUrl {
    return @"https://dev-prm-service.hktester.com";
}
- (NSArray<SLUploadFile *> *)uploadFiles {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 4; i ++) {
        SLUploadFile *file = [SLUploadFile initFileName:[NSString stringWithFormat:@"%@%@.png", @"image", @(i)] fileData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"%@%@", @"cir", @(i)] ofType:@"png"]]];
        [array addObject:file];
    }
    return array.copy;
}
- (NSDictionary *)requestHead {
    return @{@"Authorization": @"Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhY2NvdW50SWQiOjExNTcxOTMsInB1YUlkIjoxMTU3MTkzLCJleHAiOjE1ODM4MzAzMTksIm5hbWUiOiJmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmIiwiYXZhdGFyIjoiaHR0cHM6XC9cL3dlbWVkaWEwMS1zdGFnaW5nLmhrdGVzdGVyLmNvbVwvZGlcL21lZGlhXC9pbWFnZXNcL2Npc1wvNWQ4MWQ5MDhlZTJhMDQ0OTcxYzJlZDA3Lm1wNFwvZWlEMDBzcldKcVh0SVp5cXEzemUtZFFhdU44eHE1d2JoYWIwVVlXbTlGRT92PXNtYWxsIiwicG1wRW5hYmxlZCI6dHJ1ZX0.MAj_PsTgjNMpYWAM0ivyO3-NcjcfxwhRFFjrVq4-pc4U-KxuFTsc_PHvc-u41cyqAkV6xTuF163j1h-52h0RmD481JCcfHtPC01ZXKZB_Xm05YefmeoDp3LRbIXK-OgUaTd26Qm82ZAzHRinZcJ08uOwrSnF5QVLAuEbgMiRjkRMytxaOj-0YLwkUXJ4pN1GWqQ5Bh-pz7GaoUGJdJY0jdu8BpW2ahO2CvZpHptfL8aUxWAslgopPy8JyG4gsKZXY1awdb3gnWGuAqCKLYqSJHBsPzZPdPOKTfihfShFGis6R1nE3m5fUPznOeWsvasOzDCP4fx8unvff7o_x4OsnffXOwwNha9q7ZqOZdagUWQX_teHc8XtDdwn6heNitONHx5lQENSL_5QSO40I7aVJ-ukzP4dS0ZV_My1Q1hfxSmExxk3wqyCzwH53lHp5P2IUpKucZcxuixdyyh7ucg5ZnLekRD-l6bII0E2Bj5jRFbYQ0dV6Oh-FRTlIZLKLppJnbNOPKPwyXAjedkECzwvqUgG9sdGmjeYBqE__0wNvAktzPnwwKEm12xH8AeUo9S4rhSDhUM_c9KUAGLOVPMy_0Gs6OdLwtnikOmtM3XkiRuDH0lq5zy9BU1dQPiu2p7-YvfRJPWrADLOsiGkqcZSaq9yG1Nm4E09W_Ycf9MNRv4"};
}
- (NSString *)acceptContentTypes {
    return @"image/png;image/jpeg;.pdf";
}
@end
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
    return @"entity_ca/136/audits";
}
@end
@implementation PuaModel

@end
