//
//  SLDownloadManager.m
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "SLDownloadManager.h"
#import <SLNetwork/SLNetworkTool.h>

@implementation SLDownloadModel
- (void)closeOutputStream {
    if (!_outputStream) return;
    if (_outputStream.streamStatus > NSStreamStatusNotOpen && _outputStream.streamStatus < NSStreamStatusClosed) {
        [_outputStream close];
    }
    _outputStream = nil;
}

- (void)openOutputStream {
    if (!_outputStream) return;
    [_outputStream open];
}
@end

@interface SLDownloadManager()<NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableDictionary *downloadModelInfo;
@property (nonatomic, strong) NSMutableArray *downloadingModels;
@property (nonatomic, strong) NSMutableArray *waitingModels;
@end

@implementation SLDownloadManager

- (NSMutableDictionary *)downloadModelInfo {
    
    if (!_downloadModelInfo) {
        _downloadModelInfo = [NSMutableDictionary dictionary];
    }
    return _downloadModelInfo;
}

- (NSMutableArray *)downloadingModels {
    if (!_downloadingModels) {
        _downloadingModels = [NSMutableArray array];
    }
    return _downloadingModels;
}

- (NSMutableArray *)waitingModels {
    if (!_waitingModels) {
        _waitingModels = [NSMutableArray array];
    }
    return _waitingModels;
}

+ (instancetype)sharedManager{
    static SLDownloadManager *downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
        downloadManager.maxConcurrentCount = -1;
        downloadManager.queueMode = SLDownloadQueueModeFILO;
    });
    return downloadManager;
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

- (BOOL)hasSpaceDownloadQueue {
    if (self.maxConcurrentCount == -1) return YES;
    if (self.downloadingModels.count >= self.maxConcurrentCount) return NO;
    return YES;
}

- (void)download:(NSString *)urlString
           state:(void(^)(SLDownloadState state))stateBlock
        progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error))completionBlock {
    if ([SLNetworkTool sl_networkEmptyString:urlString]) return;
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *downloadFilePath = [self downloadFilePathOfURL:url];
    if ([self doneDownloadOfURL:url]) {
        if (stateBlock) stateBlock(SLDownloadStateCompleted);
        if (completionBlock) completionBlock(YES,downloadFilePath,nil);
        return;
    }
    NSString *fileName = [self fileNameOfURL:url];
    SLDownloadModel *downloadModel = self.downloadModelInfo[fileName];
    downloadModel.stateBlock = stateBlock;
    downloadModel.progressBlock = progressBlock;
    downloadModel.completionBlock = completionBlock;
    if (downloadModel) {
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"bytes=%ld-", (long)[self downloadedLengthOfURL:url]] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *dataTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                                    delegate:self
                                                        delegateQueue:[[NSOperationQueue alloc] init]] dataTaskWithRequest:request];
    dataTask.taskDescription = [self fileNameOfURL:url];
    downloadModel = [[SLDownloadModel alloc] init];
    downloadModel.dataTask = dataTask;
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadFilePath append:YES];
    downloadModel.url = url;
    self.downloadModelInfo[fileName] = downloadModel;
    [self downloadWithModel:downloadModel];
}

- (void)downloadNext {
    if (self.maxConcurrentCount == -1) return;
    if (self.waitingModels.count == 0) return;
    SLDownloadModel *downloadModel = self.waitingModels.lastObject;
    [self.waitingModels removeLastObject];
    [self downloadWithModel:downloadModel];
}

- (NSString*)fileNameOfURL:(NSURL *)url {
    if (!url) return @"";
    return [url lastPathComponent];
}

- (void)downloadWithModel:(SLDownloadModel *)downloadModel {
    SLDownloadState downloadState;
    if ([self hasSpaceDownloadQueue]) {
        [self.downloadingModels addObject:downloadModel];
        [downloadModel.dataTask resume];
        downloadState = SLDownloadStateRunning;
    } else {
        [self.waitingModels addObject:downloadModel];
        downloadState = SLDownloadStateWaiting;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.stateBlock) {
            downloadModel.stateBlock(downloadState);
        }
    });
}

- (NSString *)downloadFileDir {
    if (!_downloadFileDir) {
        _downloadFileDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    }
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:_downloadFileDir isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        [fileManager createDirectoryAtPath:_downloadFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return _downloadFileDir;
}

- (NSString *)downloadFileLengthPath {
    return [[self downloadFileDir]stringByAppendingPathComponent:@"SLDownloadTotalLength.plist"];
}

- (NSString *)downloadFilePathOfString:(NSString *)urlString {
    return [[self downloadFileDir]stringByAppendingPathComponent:urlString];
}

- (NSString *)downloadFilePathOfURL:(NSURL *)url {
    return [[self downloadFileDir]stringByAppendingPathComponent:[self fileNameOfURL:url]];
}

- (NSInteger)downloadedLengthOfURL:(NSURL *)url {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self downloadFilePathOfURL:url] error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

- (NSInteger)totalLength:(NSURL *)url {
    NSString *fileName = [self fileNameOfURL:url];
    NSDictionary *filesTotalLenthInfo = [NSDictionary dictionaryWithContentsOfFile:[self downloadFileLengthPath]];
    if (!filesTotalLenthInfo || !filesTotalLenthInfo[fileName]) {
        return 0;
    }
    return [filesTotalLenthInfo[fileName] integerValue];
}

- (BOOL)doneDownloadOfURL:(NSURL *)url {
    NSInteger totalLength = [self totalLength:url];
    if (totalLength != 0) {
        if (totalLength == [self downloadedLengthOfURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (void)suspendDownloadOfURL:(NSURL *)url {
    NSString *fileName = [self fileNameOfURL:url];
    SLDownloadModel *downloadModel = self.downloadModelInfo[fileName];
    if (!downloadModel) return;
    if (downloadModel.stateBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.stateBlock(SLDownloadStateSuspended);
        });
    }
    if ([self.waitingModels containsObject:downloadModel]) [self.waitingModels removeObject:downloadModel];
    else {
        [downloadModel.dataTask suspend];
        [self.downloadingModels removeObject:downloadModel];
    }
    [self downloadNext];
}
- (void)suspendAllDownloads {
    if (self.downloadModelInfo.count <= 0) return;
    for (int i = 0; i<self.waitingModels.count; i++) {
        SLDownloadModel *downloadModel = self.waitingModels[i];
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
    }
    [self.waitingModels removeAllObjects];
    for (int i = 0; i<self.downloadingModels.count; i++) {
        SLDownloadModel *downloadModel = self.downloadingModels[i];
        [downloadModel.dataTask suspend];
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
    }
    [self.downloadingModels removeAllObjects];
    [self downloadNext];
}

- (void)resumeDownloadOfURL:(NSURL *)url {
    NSString *fileName = [self fileNameOfURL:url];
    SLDownloadModel *downloadModel = self.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [self downloadWithModel:downloadModel];
}
- (void)resumeAllDownloads {
    if (self.downloadModelInfo.count <= 0) return;
    NSArray *downloadModels = self.downloadModelInfo.allValues;
    for (int i = 0; i<downloadModels.count; i++) {
        SLDownloadModel *downloadModel = downloadModels[i];
        [self downloadWithModel:downloadModel];
    }
}

- (void)cancelDownloadOfURL:(NSURL *)url {
    NSString *fileName = [self fileNameOfURL:url];
    SLDownloadModel *downloadModel = self.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadModel closeOutputStream];
    [downloadModel.dataTask cancel];
    if (downloadModel.stateBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.stateBlock(SLDownloadStateSuspended);
        });
    }
    if ([self.waitingModels containsObject:downloadModel]) [self.waitingModels removeObject:downloadModel];
    else {
        [self.downloadingModels removeObject:downloadModel];
    }
    [self.downloadModelInfo removeObjectForKey:fileName];
    [self downloadNext];
}
- (void)cancelAllDownloads {
    if (self.downloadModelInfo.count <= 0) return;
    NSArray *downloadModels = self.downloadModelInfo.allValues;
    for (int i = 0; i<downloadModels.count; i++) {
        SLDownloadModel *downloadModel = downloadModels[i];
        [downloadModel closeOutputStream];
        [downloadModel.dataTask cancel];
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
    }
    [self.waitingModels removeAllObjects];
    [self.downloadingModels removeAllObjects];
    [self.downloadModelInfo removeAllObjects];
}

- (void)deleteFile:(NSString *)fileName {
    if ([SLNetworkTool sl_networkEmptyString:fileName]) return;
    NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:[self downloadFileLengthPath]];
    [filesTotalLength removeObjectForKey:fileName];
    [filesTotalLength writeToFile:[self downloadFileLengthPath] atomically:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *downloadFilePath = [self downloadFilePathOfString:fileName];
    if (![fileManager fileExistsAtPath:downloadFilePath]) {
        return;
    }
    [fileManager removeItemAtPath:downloadFilePath error:nil];
}
- (void)deleteFileOfURL:(NSURL *)url {
    if (!url) return;
    [self cancelDownloadOfURL:url];
    [self deleteFile:[self fileNameOfURL:url]];
}
- (void)deleteAllFiles {
    [self cancelAllDownloads];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:[self downloadFileDir] error:nil];
    for (NSString *fileName in fileNames) {
        NSString *filePath = [self downloadFilePathOfString:fileName];;
        [fileManager removeItemAtPath:filePath error:nil];
    }
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    SLDownloadModel *downloadModel = self.downloadModelInfo[dataTask.taskDescription];
    if (!downloadModel) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    NSURL *url = downloadModel.url;
    NSString *fileName = [self fileNameOfURL:url];
    [downloadModel openOutputStream];
    NSInteger totalLength = (long)response.expectedContentLength + [self downloadedLengthOfURL:url];
    downloadModel.totalLength = totalLength;
    NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:[self downloadFileLengthPath]] ?: [NSMutableDictionary dictionary];
    filesTotalLength[fileName] = @(totalLength);
    [filesTotalLength writeToFile:[self downloadFileLengthPath] atomically:YES];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    SLDownloadModel *downloadModel = self.downloadModelInfo[dataTask.taskDescription];
    if (!downloadModel) return;
    NSURL *url = downloadModel.url;
    [downloadModel.outputStream write:data.bytes maxLength:data.length];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.progressBlock) {
            NSUInteger receivedSize = [self downloadedLengthOfURL:url];
            NSUInteger expectedSize = downloadModel.totalLength;
            if (expectedSize == 0) return;
            CGFloat progress = 1.0 * receivedSize / expectedSize;
            downloadModel.progressBlock(receivedSize, expectedSize, progress);
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error && error.code == -999) {
        return;
    }
    SLDownloadModel *downloadModel = self.downloadModelInfo[task.taskDescription];
    if (!downloadModel) return;
    NSURL *url = downloadModel.url;
    [downloadModel closeOutputStream];
    [self.downloadModelInfo removeObjectForKey:task.taskDescription];
    [self.downloadingModels removeObject:downloadModel];
    NSString *fullPath = [self downloadFilePathOfURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self doneDownloadOfURL:url]) {
            if (downloadModel.stateBlock) downloadModel.stateBlock(SLDownloadStateCompleted);
            if (downloadModel.completionBlock) downloadModel.completionBlock(YES, fullPath, nil);
        } else {
            if (downloadModel.stateBlock) downloadModel.stateBlock(SLDownloadStateFailed);
            if (downloadModel.completionBlock) downloadModel.completionBlock(NO, fullPath, error);
        }
    });
    [self downloadNext];
}
@end
