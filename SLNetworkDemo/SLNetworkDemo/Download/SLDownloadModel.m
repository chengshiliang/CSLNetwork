//
//  SLDownloadModel.m
//  SLNetworkDemo
//
//  Created by 程石亮 on 2019/12/10.
//  Copyright © 2019 程石亮. All rights reserved.
//

#import "SLDownloadModel.h"

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
