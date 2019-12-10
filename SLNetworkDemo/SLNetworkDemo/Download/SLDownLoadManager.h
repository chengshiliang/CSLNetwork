//
//  SLDownLoadManager.h
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SLDownloadModel.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, SLDownloadQueueMode) {
    SLDownloadQueueModeFIFO, // 先入先出
    SLDownloadQueueModeFILO  // 先入后出
};

@interface SLDownloadManager : NSObject
@property (nonatomic, copy) NSString *downloadFileDir;// 文件下载路径
@property (nonatomic, assign) NSInteger maxConcurrentCount;
@property (nonatomic, assign) SLDownloadQueueMode queueMode;
+ (instancetype)sharedManager;
- (void)download:(NSString *)urlString
           state:(void(^)(SLDownloadState state))stateBlock
        progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error))completionBlock;
- (NSString *)downloadFilePathOfURL:(NSURL *)URL;
#pragma mark - Downloads
- (void)suspendDownloadOfURL:(NSURL *)URL;
- (void)suspendAllDownloads;

- (void)resumeDownloadOfURL:(NSURL *)URL;
- (void)resumeAllDownloads;

- (void)cancelDownloadOfURL:(NSURL *)URL;
- (void)cancelAllDownloads;

- (void)deleteFile:(NSString *)fileName;
- (void)deleteFileOfURL:(NSURL *)URL;
- (void)deleteAllFiles;
@end

NS_ASSUME_NONNULL_END
