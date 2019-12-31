//
//  SLNetworkTool.h
//  AFNetworking
//
//  Created by 程石亮 on 2019/12/14.
//

#import <Foundation/Foundation.h>
#import <SLNetwork/SLRequestDataProtocol.h>

NS_ASSUME_NONNULL_BEGIN
@class SLRequestDataProtocol;
@interface SLNetworkTool : NSObject
+ (BOOL)sl_networkEmptyString:(NSString *)str;
+ (NSString *)dictionaryToString:(NSDictionary *)dictionary;
+ (NSString *)realUrlString:(id<SLRequestDataProtocol>)model;
+ (NSString *)requestMethodFromMethodType:(SLRequestMethod)method;
+ (NSString *)fileTypeFromFileName:(NSString *)fileName;
+ (NSString *)sl_md5String:(NSString *)string;
+ (BOOL)isUploadRequest:(NSArray<SLUploadFile *> *)files;
+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;
@end

NS_ASSUME_NONNULL_END
