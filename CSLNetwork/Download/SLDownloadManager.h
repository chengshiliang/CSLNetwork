//
//  SLDownLoadManager.h
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, SLDownloadState) {
    SLDownloadStateWaiting,
    SLDownloadStateRunning,
    SLDownloadStateSuspended,
    SLDownloadStateCanceled,
    SLDownloadStateCompleted,
    SLDownloadStateFailed
};

@interface SLDownloadManager : NSObject
@property (nonatomic, copy) NSString *downloadFileDir;// 文件下载路径
@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, assign) NSInteger maxConcurrentCount;
@property (nonatomic, copy) NSString *downloadIdentifier;
@property (nonatomic, strong) NSMutableDictionary<NSString *,void(^)(void)> *sessionCompleteHandle;
+ (instancetype)sharedManager;
- (void)download:(NSURL *)url
           state:(void(^)(SLDownloadState state))stateBlock
        progress:(void(^)(int64_t receivedSize, int64_t expectedSize, CGFloat progress))progressBlock
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error))completionBlock;
#pragma mark - Downloads
- (void)suspendDownloadOfURL:(NSURL *)URL;
- (void)suspendAllDownloads;

- (void)resumeDownloadOfURL:(NSURL *)URL;
- (void)resumeAllDownloads;

- (void)cancelDownloadOfURL:(NSURL *)URL;
- (void)cancelAllDownloads;

- (void)deleteFileOfURL:(NSURL *)URL;
- (void)deleteAllFiles;
@end

NS_ASSUME_NONNULL_END
