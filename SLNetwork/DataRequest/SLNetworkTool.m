//
//  SLNetworkTool.m
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLNetworkTool.h"
#import <CommonCrypto/CommonDigest.h>

@implementation SLNetworkTool
+ (BOOL)sl_networkEmptyString:(NSString *)str {
    if (!str) {
        return YES;
    }
    if ([str isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if (!str.length) {
        return YES;
    }
    if ([str isEqual:[NSNull null]]) {
        return YES;
    }
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [str stringByTrimmingCharactersInSet:set];
    if (!trimmedStr.length) {
        return YES;
    }
    return NO;
}
+ (NSString *)dictionaryToString:(NSDictionary *)dictionary {
    if (!dictionary || [dictionary allKeys].count <= 0) return @"";
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
+ (NSString *)realUrlString:(id<SLRequestDataProtocol>)model {
    if (!model) return @"";
    NSString *urlString = [model requestUrl];
    if ([self sl_networkEmptyString:urlString]) return @"";
    if ([urlString hasPrefix:@"http"]) return urlString;
    return [NSString stringWithFormat:@"%@%@", [model requestBaseUrl], urlString];
}
+ (NSString *)requestMethodFromMethodType:(SLRequestMethod)method {
    switch (method) {
        case SLRequestGet:
            return @"GET";
        case SLRequestPut:
            return @"PUT";
        case SLRequestPost:
            return @"POST";
        case SLRequestHead:
            return @"HEAD";
        case SLRequestDelete:
            return @"DELETE";
        case SLRequestPatch:
            return @"PATCH";
        default:
            return @"POST";
            break;
    }
}
+ (NSString *)fileTypeFromFileName:(NSString *)fileName {
    if ([self sl_networkEmptyString:fileName]) return @"";
    NSArray *components = [fileName componentsSeparatedByString:@"."];
    if (!components) return @"";
    if (components.count == 1) {
        fileName = [fileName stringByAppendingString:@".png"];
        return @"png";
    }
    return [components lastObject];
}
+ (NSString *)sl_md5String:(NSString *)string{
    const char *cStr = [string UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [self sl_md5:result];
}
+ (NSString *)sl_md5:(unsigned char [16])result{
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
+ (BOOL)isUploadRequest:(NSArray<SLUploadFile *> *)files {
    return files && files.count > 0;
}
@end
