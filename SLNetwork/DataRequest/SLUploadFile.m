//
//  SLUploadFile.m
//  SLNetwork
//
//  Created by 程石亮 on 2019/12/14.
//

#import "SLUploadFile.h"
#import <SLNetwork/SLNetworkTool.h>

@interface SLUploadFile()
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, strong) NSData *fileData;
@end

@implementation SLUploadFile
+ (instancetype)initFileName:(NSString *)name fileData:(nonnull NSData *)fileData {
    return [[self alloc]initFileName:name fileData:fileData];
}

- (instancetype)initFileName:(NSString *)name fileData:(nonnull NSData *)fileData {
    if (self == [super init]) {
        self.mimeType = [SLNetworkTool fileTypeFromFileName:name];
        if ([SLNetworkTool sl_networkEmptyString:self.mimeType]) return nil;
        self.fileName = name;
        self.name = [SLNetworkTool sl_md5String:name];
        self.fileData = fileData;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"\nfileName: %@\nmineType: %@\nname: %@",self.fileName,self.mimeType,self.name];
}
@end
