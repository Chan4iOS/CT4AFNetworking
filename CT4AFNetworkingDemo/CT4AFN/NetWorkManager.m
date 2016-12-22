//
//  NetWorkManager.m
//
//  Created by 陈世翰 on 16/5/20.
//  Copyright © 2016年 陈世翰. All rights reserved.
//

#import "NetWorkManager.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVMediaFormat.h>

#import "UIImage+compressIMG.h"
@interface NetWorkManager(){
    NSMutableDictionary *_progress;
}

@end


@implementation NetWorkManager



#pragma mark - shareManager
/**
 *  获得全局唯一的网络请求实例单例方法
 *
 *  @return 网络请求类的实例
 */

+(instancetype)shareManager
{
    
    static NetWorkManager * manager = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURL *mainURL;
        if (![NetWorkManager_BASE_URL isEqualToString:@""]) {
            mainURL = [NSURL URLWithString:NetWorkManager_BASE_URL];
        }
        manager = [[self alloc] initWithBaseURL:mainURL];
        
    });
    
    return manager;
}


#pragma mark - 重写initWithBaseURL
/**
 *
 *
 *  @param url baseUrl
 *
 *  @return 通过重写夫类的initWithBaseURL方法,返回网络请求类的实例
 */

-(instancetype)initWithBaseURL:(NSURL *)url
{
    
    if (self = [super initWithBaseURL:url]) {
        
        /**设置请求超时时间*/
        
        self.requestSerializer.timeoutInterval = 30;
        
        /**设置相应的缓存策略*/
        
        self.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        
        /**分别设置请求以及相应的序列化器*/
        //        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        
        AFJSONResponseSerializer * response = [AFJSONResponseSerializer serializer];
        
        response.removesKeysWithNullValues = YES;
        
        self.responseSerializer = response;
        
        /**复杂的参数类型 需要使用json传值-设置请求内容的类型*/
        
        [self.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        
//        此处做为测试 可根据自己应用设置相应的值
        
        /**设置apikey ------类似于自己应用中的tokken---此处仅仅作为测试使用*/
        
        //        [self.requestSerializer setValue:apikey forHTTPHeaderField:@"apikey"];
        
        
        
        /**设置接受的类型*/
        [self.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/plain",@"application/json",@"text/json",@"text/javascript",@"text/html", nil]];
        
    }
    
    return self;
}


#pragma mark - 网络请求的类方法---get/post

/**
 *  网络请求的实例方法
 *
 *  @param type         get / post
 *  @param urlString    请求的地址
 *  @param paraments    请求的参数
 *  @param successBlock 请求成功的回调
 *  @param failureBlock 请求失败的回调
 *  @param progress 进度
 */

+(NSURLSessionDataTask *)requestWithType:(HttpRequestType)type withUrlString:(NSString *)urlString withParaments:(id)paraments withSuccessBlock:(requestSuccess)successBlock withFailureBlock:(requestFailure)failureBlock progress:(downloadProgress)progress
{
    
    
    switch (type) {
            
        case HttpRequestTypeGet:
        {
            
            
            return   [[NetWorkManager shareManager] GET:urlString parameters:paraments progress:^(NSProgress * _Nonnull downloadProgress) {
                
                if (progress) {
                    progress(downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
                }
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                successBlock(responseObject);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                failureBlock(error);
            }];
            
            break;
        }
            
        case HttpRequestTypePost:
            
        {
            
            return  [[NetWorkManager shareManager] POST:urlString parameters:paraments progress:^(NSProgress * _Nonnull uploadProgress) {
                if (progress) {
                    progress(uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
                }
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                successBlock(responseObject);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                failureBlock(error);
                
            }];
            break;
        }
            
        case HttpRequestTypePostInBody:{
            
            NSMutableData *body = [NSMutableData data];
            [body appendData:[paraments dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Contsetent-Type"];
            [request setHTTPBody:body];
            [request setTimeoutInterval:30.0f];
            NSURLSessionDataTask *dataTask = [[NetWorkManager shareManager] dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                if (error) {
                    failureBlock(error);
                } else {
                    successBlock(responseObject);
                }
            }];
            [dataTask resume];
            return dataTask;
        }
            
    }
    return nil;
    
}


#pragma mark - 多图上传
/**
 *  上传图片
 *
 *  @param operations   上传图片等预留参数---视具体情况而定 可移除
 *  @param imageArray   上传的图片数组
 *  @parm width      图片要被压缩到的宽度
 *  @param urlString    上传的url---请填写完整的url
 *  @param successBlock 上传成功的回调
 *  @param failureBlock 上传失败的回调
 *  @param progress     上传进度
 *
 */
+(void)uploadImageWithOperations:(NSDictionary *)operations withImageArray:(NSArray *)imageArray withtargetWidth:(CGFloat )width withUrlString:(NSString *)urlString withSuccessBlock:(requestSuccess)successBlock withFailurBlock:(requestFailure)failureBlock withUpLoadProgress:(uploadProgress)progress;
{
    
    
    //1.创建管理者对象
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager POST:urlString parameters:operations constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSUInteger i = 0 ;
        
        /**出于性能考虑,将上传图片进行压缩*/
        for (UIImage * image in imageArray) {
            
            //image的分类方法
            UIImage *  resizedImage =  [UIImage IMGCompressed:image targetWidth:width];
            
            NSData * imgData = UIImageJPEGRepresentation(resizedImage, .5);
            
            //拼接data
            [formData appendPartWithFileData:imgData name:[NSString stringWithFormat:@"picflie%ld",(long)i] fileName:@"image.png" mimeType:@" image/jpeg"];
            
            i++;
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress) {
            progress(uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
        
        successBlock(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failureBlock(error);
        
    }];
}



#pragma mark - 视频上传

/**
 *  视频上传
 *
 *  @param operations   上传视频预留参数---视具体情况而定 可移除
 *  @param videoPath    上传视频的本地沙河路径
 *  @param urlString     上传的url
 *  @param successBlock 成功的回调
 *  @param failureBlock 失败的回调
 *  @param progress     上传的进度
 */

+(void)uploadVideoWithOperaitons:(NSDictionary *)operations withVideoPath:(NSString *)videoPath withUrlString:(NSString *)urlString withSuccessBlock:(requestSuccess)successBlock withFailureBlock:(requestFailure)failureBlock withUploadProgress:(uploadProgress)progress
{
    
    
    /**获得视频资源*/
    
    AVURLAsset * avAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:videoPath]];
    
    /**压缩*/
    
    //    NSString *const AVAssetExportPreset640x480;
    //    NSString *const AVAssetExportPreset960x540;
    //    NSString *const AVAssetExportPreset1280x720;
    //    NSString *const AVAssetExportPreset1920x1080;
    //    NSString *const AVAssetExportPreset3840x2160;
    
    AVAssetExportSession  *  avAssetExport = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset640x480];
    
    /**创建日期格式化器*/
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    
    /**转化后直接写入Library---caches*/
    
    NSString *  videoWritePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:[NSString stringWithFormat:@"/output-%@.mp4",[formatter stringFromDate:[NSDate date]]]];
    
    
    avAssetExport.outputURL = [NSURL URLWithString:videoWritePath];
    
    
    avAssetExport.outputFileType =  AVFileTypeMPEG4;
    
    
    [avAssetExport exportAsynchronouslyWithCompletionHandler:^{
        
        
        switch ([avAssetExport status]) {
                
                
            case AVAssetExportSessionStatusCompleted:
            {
                
                
                
                AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
                
                [manager POST:urlString parameters:operations constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    
                    //获得沙盒中的视频内容
                    
                    [formData appendPartWithFileURL:[NSURL fileURLWithPath:videoWritePath] name:@"write you want to writre" fileName:videoWritePath mimeType:@"video/mpeg4" error:nil];
                    
                } progress:^(NSProgress * _Nonnull uploadProgress) {
                    
                    if (progress) {
                        progress(uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
                    }
                    
                    
                } success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary *  _Nullable responseObject) {
                    
                    successBlock(responseObject);
                    
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    
                    failureBlock(error);
                    
                }];
                
                break;
            }
            default:
                break;
        }
        
        
    }];
    
}

#pragma mark - 文件下载


/**
 *  文件下载
 *
 *  @param operations   文件下载预留参数---视具体情况而定 可移除
 *  @param savePath     下载文件保存路径
 *  @param urlString        请求的url
 *  @param successBlock 下载文件成功的回调
 *  @param failureBlock 下载文件失败的回调
 *  @param progress     下载文件的进度显示
 */

+(NSURLSessionDownloadTask *)downLoadFileWithOperations:(NSDictionary *)operations withSavaPath:(NSString *)savePath withUrlString:(NSString *)urlString withSuccessBlock:(requestSuccess)successBlock withFailureBlock:(requestFailure)failureBlock withDownLoadProgress:(downloadProgress)progress
{
    
    
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    
    
    NSURLSessionDownloadTask *downloadTask =  [manager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progress) {
            progress(downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        }
        
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        return  [NSURL URLWithString:savePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if (error) {
            
            failureBlock(error);
        }
        
    }];
    
    return downloadTask;
}

+ (unsigned long long)fileSizeForPath:(NSString *)path {
    
    signed long long fileSize = 0;
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:path]) {
        
        NSError *error = nil;
        
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        
        if (!error && fileDict) {
            
            fileSize = [fileDict fileSize];
        }
    }
    
    return fileSize;
}

#pragma mark -  取消所有的网络请求

/**
 *  取消所有的网络请求
 *  a finished (or canceled) operation is still given a chance to execute its completion block before it iremoved from the queue.
 */

+(void)cancelAllRequest
{
    
    [[NetWorkManager shareManager].operationQueue cancelAllOperations];
    
}



#pragma mark -   取消指定的url请求/
/**
 *  取消指定的url请求
 *
 *  @param requestType 该请求的请求类型
 *  @param string      该请求的完整url
 */

+(void)cancelHttpRequestWithRequestType:(NSString *)requestType requestUrlString:(NSString *)string
{
    
    NSError * error;
    
    /**根据请求的类型 以及 请求的url创建一个NSMutableURLRequest---通过该url去匹配请求队列中是否有该url,如果有的话 那么就取消该请求*/
    
    NSString * urlToPeCanced = [[[[NetWorkManager shareManager].requestSerializer requestWithMethod:requestType URLString:string parameters:nil error:&error] URL] path];
    
    
    for (NSOperation * operation in [NetWorkManager shareManager].operationQueue.operations) {
        
        //如果是请求队列
        if ([operation isKindOfClass:[NSURLSessionTask class]]) {
            
            //请求的类型匹配
            BOOL hasMatchRequestType = [requestType isEqualToString:[[(NSURLSessionTask *)operation currentRequest] HTTPMethod]];
            
            //请求的url匹配
            
            BOOL hasMatchRequestUrlString = [urlToPeCanced isEqualToString:[[[(NSURLSessionTask *)operation currentRequest] URL] path]];
            
            //两项都匹配的话  取消该请求
            if (hasMatchRequestType&&hasMatchRequestUrlString) {
                
                [operation cancel];
                
            }
        }
        
    }
}


#pragma mark -断点下载

/**
 *  文件下载
 *
 *  @param operations   文件下载预留参数---视具体情况而定 可移除
 *  @param savePath     下载文件保存路径
 
 *  @param progress     下载文件的进度显示
 */

//+(NSURLSessionDataTask *)continuedDownLoadFileWithSavaPath:(NSString *)savePath withUrlString:(NSString *)urlString withSuccessBlock:(requestSuccess)successBlock withFailureBlock:(commonFailure)failureBlock withDownLoadProgress:(commonProgress)progress
//{
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:urlString]];
//
//    long long downloadedBytes =[self fileSizeForPath:savePath];
//    if (downloadedBytes > 0) {
//
//        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
//        [request setValue:requestRange forHTTPHeaderField:@"Range"];
//    }else{
//
//        int fileDescriptor = open([savePath UTF8String],O_CREAT |O_EXCL |O_RDWR,0666);
//        if (fileDescriptor > 0) {
//            close(fileDescriptor);
//        }
//    }
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
////    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"video/mpeg",nil]];
//    NSURLSessionDataTask *dataTask =  [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil receiveData:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
//        long long totalContentLength=0;
//        //根据status code的不同，做相应的处理
//        NSHTTPURLResponse *response = (NSHTTPURLResponse*)dataTask.response;
//        if (response.statusCode ==200) {
//
//            totalContentLength = dataTask.countOfBytesExpectedToReceive;
//
//        }else if (response.statusCode ==206){//客户发送了一个带有Range头的GET请求（分块请求），服务器完成了它
//
//            NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
//            if ([contentRange hasPrefix:@"bytes"]) {
//                NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
//                if ([bytes count] == 4) {
//                    totalContentLength = [[bytes objectAtIndex:3]longLongValue];
//                }
//            }
//        }else if (response.statusCode ==416){//Requested Range Not Satisfiable 服务器不能满足客户在请求中指定的Range头
//
//            NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
//            if ([contentRange hasPrefix:@"bytes"]) {
//                NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
//                if ([bytes count] == 3) {
//
//                    totalContentLength = [[bytes objectAtIndex:2]longLongValue];
//                    if (downloadedBytes==totalContentLength) {
//
//                        //说明已下完
//
//                        //更新进度
//                        if (progress) {
//                            progress(1,totalContentLength*1.f/ 1024.f / 1024.0f,totalContentLength*1.f/ 1024.f / 1024.0f);
//                        }
//                    }else{
//
//                        if (failureBlock) {
//                            failureBlock(@"416:wrong");
//                        }
//
//                    }
//                }
//            }else{
//                if (successBlock) {
//                    successBlock(nil);
//                }
//            }
//            return;
//        }
//        if (response.statusCode == 404) {
//            if (failureBlock) {
//                failureBlock(@"404:url不存在");
//            }
//        }
//
//        //向文件追加数据
//        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:savePath];
//        [fileHandle seekToEndOfFile]; //将节点跳到文件的末尾
//
//        [fileHandle writeData:data];//追加写入数据
//        [fileHandle closeFile];
//
//        //更新进度
//        CGFloat curread =[self fileSizeForPath:savePath];
//        CGFloat progressValue =curread*1.f/totalContentLength;
//        if (progress) {
//            progress(progressValue,curread*1.f / 1024.f / 1024.0f,totalContentLength*1.f/ 1024.f / 1024.0f);
//        };
//    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
//        //-1009 断网  -1011 已经有该文件
//        if (error.code == -1009) {
//            if (failureBlock) {
//                failureBlock(@"-1009:wrong网络中断");
//            }
//        }
//        if (error == nil) {
//            successBlock(nil);
//        }
//    }];
//    return dataTask;
//}


+(NSURLSessionDataTask *)continuedDownLoadFileWithSavaPath:(NSString *)savePath withUrlString:(NSString *)urlString withSuccessBlock:(requestSuccess)successBlock withFailureBlock:(commonFailure)failureBlock withDownLoadProgress:(commonProgress)progress
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:urlString]];
    
    long long downloadedBytes =[self fileSizeForPath:savePath];
    if (downloadedBytes > 0) {
        
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
        [request setValue:requestRange forHTTPHeaderField:@"Range"];
    }else{
        
        int fileDescriptor = open([savePath UTF8String],O_CREAT |O_EXCL |O_RDWR,0666);
        if (fileDescriptor > 0) {
            close(fileDescriptor);
        }
    }
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"video/mpeg",nil]];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        //-1009 断网  -1011 已经有该文件
        if (error.code == -1009) {
            if (failureBlock) {
                failureBlock(@"-1009:wrong网络中断");
            }
        }
        if (error == nil) {
            successBlock(nil);
        }
        
    }];
    [manager  setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        
        long long totalContentLength=0;
        //根据status code的不同，做相应的处理
        NSHTTPURLResponse *response = (NSHTTPURLResponse*)dataTask.response;
        if (response.statusCode ==200) {
            
            totalContentLength = dataTask.countOfBytesExpectedToReceive;
            
        }else if (response.statusCode ==206){//客户发送了一个带有Range头的GET请求（分块请求），服务器完成了它
            
            NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
            if ([contentRange hasPrefix:@"bytes"]) {
                NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
                if ([bytes count] == 4) {
                    totalContentLength = [[bytes objectAtIndex:3]longLongValue];
                }
            }
        }else if (response.statusCode ==416){//Requested Range Not Satisfiable 服务器不能满足客户在请求中指定的Range头
            
            NSString *contentRange = [response.allHeaderFields valueForKey:@"Content-Range"];
            if ([contentRange hasPrefix:@"bytes"]) {
                NSArray *bytes = [contentRange componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
                if ([bytes count] == 3) {
                    
                    totalContentLength = [[bytes objectAtIndex:2]longLongValue];
                    if (downloadedBytes==totalContentLength) {
                        
                        //说明已下完
                        
                        //更新进度
                        if (progress) {
                            progress(1,totalContentLength*1.f/ 1024.f / 1024.0f,totalContentLength*1.f/ 1024.f / 1024.0f);
                        }
                    }else{
                        
                        if (failureBlock) {
                            failureBlock(@"416:wrong");
                        }
                        
                    }
                }
            }else{
                if (successBlock) {
                    successBlock(nil);
                }
            }
            return;
        }
        if (response.statusCode == 404) {
            if (failureBlock) {
                failureBlock(@"404:url不存在");
            }
        }
        
        //向文件追加数据
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:savePath];
        [fileHandle seekToEndOfFile]; //将节点跳到文件的末尾
        
        [fileHandle writeData:data];//追加写入数据
        [fileHandle closeFile];
        
        //更新进度
        CGFloat curread =[self fileSizeForPath:savePath];
        CGFloat progressValue =curread*1.f/totalContentLength;
        if (progress) {
            progress(progressValue,curread*1.f / 1024.f / 1024.0f,totalContentLength*1.f/ 1024.f / 1024.0f);
        };
        
    }];
    return dataTask;
}





@end
