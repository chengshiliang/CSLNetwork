//
//  SLNetworkTool.m
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLNetworkTool.h"

@implementation SLNetworkTool
+ (NSString *)dictionaryToString:(NSDictionary *)dictionary {
    if (!dictionary || [dictionary allKeys].count <= 0) return @"";
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
@end
