//
//  SLNetworkTool.m
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLNetworkTool.h"

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
@end
