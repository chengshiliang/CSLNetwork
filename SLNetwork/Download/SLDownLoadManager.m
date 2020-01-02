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
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@end

@implementation SLDownloadManager
static SLDownloadManager *downloadManager;
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[self alloc] init];
        downloadManager.maxConcurrentCount = -1;
        downloadManager.queueMode = SLDownloadQueueModeFILO;
        downloadManager.lock = [NSLock new];
        downloadManager.downloadQueue = dispatch_queue_create("com.sl.download", DISPATCH_QUEUE_CONCURRENT);
    });
    return downloadManager;
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

- (BOOL)hasSpaceDownloadQueue {
    if (downloadManager.maxConcurrentCount == -1) return YES;
    if (downloadManager.downloadingModels.count >= downloadManager.maxConcurrentCount) return NO;
    return YES;
}

- (void)download:(NSString *)urlString
           state:(void(^)(SLDownloadState state))stateBlock
        progress:(void(^)(NSInteger receivedSize, NSInteger expectedSize, CGFloat progress))progressBlock
      completion:(void(^)(BOOL isSuccess, NSString *filePath, NSError *_Nullable error))completionBlock {
    if ([SLNetworkTool sl_networkEmptyString:urlString]) return;
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *downloadFilePath = [downloadManager downloadFilePathOfURL:url];
    if ([downloadManager doneDownloadOfURL:url]) {
        if (stateBlock) stateBlock(SLDownloadStateCompleted);
        if (completionBlock) completionBlock(YES,downloadFilePath,nil);
        return;
    }
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    downloadModel.stateBlock = stateBlock;
    downloadModel.progressBlock = progressBlock;
    downloadModel.completionBlock = completionBlock;
    if (downloadModel) {
        return;
    }
    [downloadManager.lock lock];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"bytes=%ld-", (long)[downloadManager downloadedLengthOfURL:url]] forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *dataTask = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                                    delegate:downloadManager
                                                               delegateQueue:[[NSOperationQueue alloc] init]]
                                      dataTaskWithRequest:request];
    dataTask.taskDescription = fileName;
    downloadModel = [[SLDownloadModel alloc] init];
    downloadModel.dataTask = dataTask;
    downloadModel.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadFilePath append:YES];
    downloadModel.url = url;
    downloadManager.downloadModelInfo[fileName] = downloadModel;
    [downloadManager.lock unlock];
    [downloadManager downloadWithModel:downloadModel];
}

- (void)downloadNext {
    if (downloadManager.maxConcurrentCount == -1) return;
    if (downloadManager.waitingModels.count == 0) return;
    [downloadManager.lock lock];
    SLDownloadModel *downloadModel = downloadManager.waitingModels.lastObject;
    [downloadManager.waitingModels removeLastObject];
    [downloadManager downloadWithModel:downloadModel];
    [downloadManager.lock unlock];
}

- (NSString*)fileNameOfURL:(NSURL *)url {
    if (!url) return @"";
    return [url lastPathComponent];
}

- (void)downloadWithModel:(SLDownloadModel *)downloadModel {
    [downloadManager.lock lock];
    if ([downloadManager hasSpaceDownloadQueue]) {
        [downloadManager.downloadingModels addObject:downloadModel];
        [downloadModel.dataTask resume];
        downloadModel.state = SLDownloadStateRunning;
    } else {
        [downloadManager.waitingModels addObject:downloadModel];
        downloadModel.state = SLDownloadStateWaiting;
    }
    [downloadManager.lock unlock];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.stateBlock) {
            downloadModel.stateBlock(downloadModel.state);
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
    return [[downloadManager downloadFileDir]stringByAppendingPathComponent:@"SLDownloadTotalLength.plist"];
}

- (NSString *)downloadFilePathOfString:(NSString *)urlString {
    return [[downloadManager downloadFileDir]stringByAppendingPathComponent:urlString];
}

- (NSString *)downloadFilePathOfURL:(NSURL *)url {
    return [[downloadManager downloadFileDir]stringByAppendingPathComponent:[downloadManager fileNameOfURL:url]];
}

- (NSInteger)downloadedLengthOfURL:(NSURL *)url {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[downloadManager downloadFilePathOfURL:url] error:nil];
    if (!fileAttributes) {
        return 0;
    }
    return [fileAttributes[NSFileSize] integerValue];
}

- (NSInteger)totalLength:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    NSDictionary *filesTotalLenthInfo = [NSDictionary dictionaryWithContentsOfFile:[downloadManager downloadFileLengthPath]];
    if (!filesTotalLenthInfo || !filesTotalLenthInfo[fileName]) {
        return 0;
    }
    return [filesTotalLenthInfo[fileName] integerValue];
}

- (BOOL)doneDownloadOfURL:(NSURL *)url {
    NSInteger totalLength = [downloadManager totalLength:url];
    if (totalLength != 0) {
        if (totalLength == [downloadManager downloadedLengthOfURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (void)suspendDownloadOfURL:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadManager.lock lock];
    downloadModel.state = SLDownloadStateSuspended;
    if (downloadModel.stateBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.stateBlock(SLDownloadStateSuspended);
        });
    }
    if ([downloadManager.waitingModels containsObject:downloadModel]) [downloadManager.waitingModels removeObject:downloadModel];
    else {
        [downloadModel.dataTask suspend];
        [downloadManager.downloadingModels removeObject:downloadModel];
    }
    [downloadManager.lock unlock];
    [downloadManager downloadNext];
}
- (void)suspendAllDownloads {
    if (downloadManager.downloadModelInfo.count <= 0) return;
    [downloadManager.lock lock];
    for (int i = 0; i<downloadManager.waitingModels.count; i++) {
        SLDownloadModel *downloadModel = downloadManager.waitingModels[i];
        downloadModel.state = SLDownloadStateSuspended;
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
    }
    [downloadManager.waitingModels removeAllObjects];
    for (int i = 0; i<downloadManager.downloadingModels.count; i++) {
        SLDownloadModel *downloadModel = downloadManager.downloadingModels[i];
        [downloadModel.dataTask suspend];
        downloadModel.state = SLDownloadStateSuspended;
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
    }
    [downloadManager.downloadingModels removeAllObjects];
    [downloadManager.lock unlock];
    [downloadManager downloadNext];
}

- (void)resumeDownloadOfURL:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadManager downloadWithModel:downloadModel];
}
- (void)resumeAllDownloads {
    if (downloadManager.downloadModelInfo.count <= 0) return;
    NSArray *downloadModels = downloadManager.downloadModelInfo.allValues;
    for (int i = 0; i<downloadModels.count; i++) {
        SLDownloadModel *downloadModel = downloadModels[i];
        [downloadManager downloadWithModel:downloadModel];
    }
}

- (void)cancelDownloadOfURL:(NSURL *)url {
    NSString *fileName = [downloadManager fileNameOfURL:url];
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[fileName];
    if (!downloadModel) return;
    [downloadManager.lock lock];
    [downloadModel closeOutputStream];
    [downloadModel.dataTask cancel];
    downloadModel.state = SLDownloadStateSuspended;
    if (downloadModel.stateBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            downloadModel.stateBlock(SLDownloadStateSuspended);
        });
    }
    if ([downloadManager.waitingModels containsObject:downloadModel]) [downloadManager.waitingModels removeObject:downloadModel];
    else {
        [downloadManager.downloadingModels removeObject:downloadModel];
    }
    [downloadManager.downloadModelInfo removeObjectForKey:fileName];
    [downloadManager.lock unlock];
    [downloadManager downloadNext];
}
- (void)cancelAllDownloads {
    if (downloadManager.downloadModelInfo.count <= 0) return;
    [downloadManager.lock lock];
    NSArray *downloadModels = downloadManager.downloadModelInfo.allValues;
    for (int i = 0; i<downloadModels.count; i++) {
        SLDownloadModel *downloadModel = downloadModels[i];
        [downloadModel closeOutputStream];
        [downloadModel.dataTask cancel];
        downloadModel.state = SLDownloadStateSuspended;
        if (downloadModel.stateBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                downloadModel.stateBlock(SLDownloadStateSuspended);
            });
        }
    }
    [downloadManager.waitingModels removeAllObjects];
    [downloadManager.downloadingModels removeAllObjects];
    [downloadManager.downloadModelInfo removeAllObjects];
    [downloadManager.lock unlock];
}

- (void)deleteFile:(NSString *)fileName {
    if ([SLNetworkTool sl_networkEmptyString:fileName]) return;
    dispatch_async(downloadManager.downloadQueue, ^{
        NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:[downloadManager downloadFileLengthPath]];
        [filesTotalLength removeObjectForKey:fileName];
        [filesTotalLength writeToFile:[downloadManager downloadFileLengthPath] atomically:YES];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *downloadFilePath = [downloadManager downloadFilePathOfString:fileName];
        if ([fileManager fileExistsAtPath:downloadFilePath]) {
            [fileManager removeItemAtPath:downloadFilePath error:nil];
        }
    });
}
- (void)deleteFileOfURL:(NSURL *)url {
    if (!url) return;
    [downloadManager cancelDownloadOfURL:url];
    [downloadManager deleteFile:[downloadManager fileNameOfURL:url]];
}
- (void)deleteAllFiles {
    [downloadManager cancelAllDownloads];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    dispatch_async(downloadManager.downloadQueue, ^{
        NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:[downloadManager downloadFileDir] error:nil];
        for (NSString *fileName in fileNames) {
            NSString *filePath = [downloadManager downloadFilePathOfString:fileName];;
            [fileManager removeItemAtPath:filePath error:nil];
        }
    });
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[dataTask.taskDescription];
    if (!downloadModel) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    NSURL *url = downloadModel.url;
    NSString *fileName = [downloadManager fileNameOfURL:url];
    [downloadModel openOutputStream];
    NSInteger totalLength = (long)response.expectedContentLength + [downloadManager downloadedLengthOfURL:url];
    downloadModel.totalLength = totalLength;
    NSMutableDictionary *filesTotalLength = [NSMutableDictionary dictionaryWithContentsOfFile:[downloadManager downloadFileLengthPath]] ?: [NSMutableDictionary dictionary];
    filesTotalLength[fileName] = @(totalLength);
    [filesTotalLength writeToFile:[downloadManager downloadFileLengthPath] atomically:YES];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[dataTask.taskDescription];
    if (!downloadModel) return;
    NSURL *url = downloadModel.url;
    [downloadModel.outputStream write:data.bytes maxLength:data.length];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (downloadModel.progressBlock) {
            NSUInteger receivedSize = [downloadManager downloadedLengthOfURL:url];
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
    SLDownloadModel *downloadModel = downloadManager.downloadModelInfo[task.taskDescription];
    if (!downloadModel) return;
    NSURL *url = downloadModel.url;
    [downloadModel closeOutputStream];
    [downloadManager.downloadModelInfo removeObjectForKey:task.taskDescription];
    [downloadManager.downloadingModels removeObject:downloadModel];
    NSString *fullPath = [downloadManager downloadFilePathOfURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([downloadManager doneDownloadOfURL:url]) {
            downloadModel.state = SLDownloadStateCompleted;
            if (downloadModel.stateBlock) downloadModel.stateBlock(SLDownloadStateCompleted);
            if (downloadModel.completionBlock) downloadModel.completionBlock(YES, fullPath, nil);
        } else {
            downloadModel.state = SLDownloadStateFailed;
            if (downloadModel.stateBlock) downloadModel.stateBlock(SLDownloadStateFailed);
            if (downloadModel.completionBlock) downloadModel.completionBlock(NO, fullPath, error);
        }
    });
    [downloadManager downloadNext];
}
@end
