//
//  WeUpload.m
//  UIImageControllerTest
//
//  Created by vhall on 2019/5/14.
//  Copyright © 2019 vhall. All rights reserved.
//

#import "WeUpload.h"
#import <Photos/Photos.h>
#import "AFHTTPSessionManager.h"

AFHTTPSessionManager *_manager = nil;

///iCloud文件上传使用
@interface WeDocument : UIDocument

@property (nonatomic, strong, nullable) NSData *data;
//文件名
@property (nonatomic, copy, nullable) NSString *fileName;
//文件类型
@property (nonatomic, copy, nullable) NSString *MIMEType;
//文件大小
@property (nonatomic, assign) NSUInteger length;

@end

@implementation WeDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError
{
    //目前不支持.page
    if ([contents isKindOfClass:[NSData class]])
    {
        self.data = [contents copy];
        self.fileName = self.fileURL.lastPathComponent;
        if (self.fileName && self.fileName.length) {
            NSRange startRange = [self.fileName rangeOfString:@"."];
            self.MIMEType = [self.fileName substringFromIndex:startRange.location];
        }
        self.length = self.data.length;
    }
    else {
        NSLog(@"读取文件出错！");
        return NO;
    }
    return YES;
}

@end



@implementation WeUpload

/**
 *  iCloud文件上传
 *  documentsURL 文件地址；rename 文件重命名，文件名不需带文件类型后缀
 */
+ (void)uploadICloudFileWithUrl:(NSURL *)documentsURL
                         reName:(nullable NSString *)rename
                       progress:(nullable void (^)(NSProgress * progress))uploadProgress
                         sucess:(void(^)(NSDictionary *responseObject))uploadSuccess
                        failure:(void(^)(NSError *error))uploadFailure
{
    if (!documentsURL.isFileURL) {
        [self onError:[NSError errorWithDomain:@"URL error , is not file url" code:-1 userInfo:nil] errorBlock:uploadFailure];
        return;
    }
    
    WeDocument *document = [[WeDocument alloc] initWithFileURL:documentsURL];
    
    //打开文件
    [document openWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            //文件重命名
            if (rename && rename.length>0) {
                //server端从文件名中获取后缀，进行文档转化，因此文件名需要包含文件类型后缀
                document.fileName = [rename stringByAppendingString:document.MIMEType];
            }
            
            //上传
            [WeUpload uploadWithFileData:document.data fileName:document.fileName fileType:document.MIMEType progress:^(NSProgress *progress) {
                [WeUpload progress:progress progressBlock:uploadProgress];
            } success:^(NSDictionary *responseObject) {
                [WeUpload onSucess:responseObject sucessBlock:uploadSuccess];
            } failure:^(NSError *error) {
                [WeUpload onError:error errorBlock:uploadFailure];
            }];
        }
        else
        {
            [WeUpload onError:[NSError errorWithDomain:@"文件读取失败" code:-1 userInfo:nil] errorBlock:uploadFailure];
        }
        [document closeWithCompletionHandler:^(BOOL success) {
            
        }];
    }];
}

/**
 图片上传，相册、拍照文件上传。
 url为referenceURL，相册UIImagePickerControllerReferenceURL，拍照PHImageFileURLKey，可为空，为空时不会上传源文件名称。
 rename，通过此值修改上传文件名称，文件名不需带文件类型后缀。
 */
+ (void)uploadImage:(UIImage *)image
       referenceURL:(nullable NSURL *)url
             reName:(nullable NSString *)rename
           progress:(nullable void (^)(NSProgress * progress))uploadProgress
             sucess:(void(^)(NSDictionary *responseObject))uploadSuccess
            failure:(void(^)(NSError *error))uploadFailure
{
    if (!image) {
        [self onError:[NSError errorWithDomain:@"文件为空！" code:10020 userInfo:nil] errorBlock:uploadFailure];
        return;
    }
    if (![image isKindOfClass:[UIImage class]]) {
        [self onError:[NSError errorWithDomain:@"文件格式不支持！" code:40010 userInfo:nil] errorBlock:uploadFailure];
        return;
    }
    
    //文件
    NSData *data = UIImageJPEGRepresentation(image, 0.8);
    
    //相册资源
    __block NSURL *FileURL = url;
    if ([url.absoluteString containsString:@"assets-library"])
    {
        //读取文件信息
        PHFetchResult*result = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
        PHAsset *asset = [result firstObject];
        PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:phImageRequestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            
            FileURL = info[@"PHImageFileURLKey"];
            
            //默认类型png
            NSString *mimeType = @".png";
            //默认名称
            NSString *fileName = [FileURL lastPathComponent];
            //MIMEType
            if (fileName && fileName.length) {
                NSRange startRange = [fileName rangeOfString:@"."];
                mimeType = [fileName substringFromIndex:startRange.location];
            }
            //重命名
            if (rename && rename.length>0) {
                //server端从文件名中获取后缀，进行文档转化，因此文件名需要包含文件类型后缀
                fileName = [rename stringByAppendingString:mimeType];
            }
            //上传
            [WeUpload uploadWithFileData:data fileName:fileName fileType:mimeType progress:^(NSProgress *progress) {
                [WeUpload progress:progress progressBlock:uploadProgress];
            } success:^(NSDictionary *responseObject) {
                [WeUpload onSucess:responseObject sucessBlock:uploadSuccess];
            } failure:^(NSError *error) {
                [WeUpload onError:error errorBlock:uploadFailure];
            }];
        }];
    }
    //拍照资源文件/其他
    else
    {
        //默认类型png
        NSString *mimeType = @".png";
        //默认名称
        NSString *fileName = [FileURL lastPathComponent];
        //MIMEType
        if (fileName && fileName.length) {
            NSRange startRange = [fileName rangeOfString:@"."];
            mimeType = [fileName substringFromIndex:startRange.location];
        }
        //重命名
        if (rename && rename.length>0) {
            //server端从文件名中获取后缀，进行文档转化，因此文件名需要包含文件类型后缀
            fileName = [rename stringByAppendingString:mimeType];
        }
        //上传
        [WeUpload uploadWithFileData:data fileName:fileName fileType:mimeType progress:^(NSProgress *progress) {
            [WeUpload progress:progress progressBlock:uploadProgress];
        } success:^(NSDictionary *responseObject) {
            [WeUpload onSucess:responseObject sucessBlock:uploadSuccess];
        } failure:^(NSError *error) {
            [WeUpload onError:error errorBlock:uploadFailure];
        }];
    }
}


#pragma mark - 回调
+ (void)onError:(NSError *)error errorBlock:(void(^)(NSError *error))uploadFailure {
    if (uploadFailure) {
        uploadFailure(error);
    }
}
+ (void)onSucess:(NSDictionary *)response sucessBlock:(void(^)(NSDictionary *responseObject))uploadSuccess {
    if (uploadSuccess) {
        uploadSuccess(response);
    }
}
+ (void)progress:(NSProgress *)progress progressBlock:(nullable void (^)(NSProgress * progress))uploadProgress {
    if (uploadProgress) {
        uploadProgress(progress);
    }
}


#pragma mark - 上传
+ (void)uploadWithFileData:(NSData *)data fileName:(nullable NSString *)name fileType:(NSString *)type progress:(nullable void (^)(NSProgress * progress))WeUploadProgress success:(void(^)(NSDictionary *responseObject))success failure:(void(^)(NSError *error))failure
{
    //文件类型获取失败，return，否则会闪退
    if (!type || type.length <= 0) {
        if (failure) {
            failure([NSError errorWithDomain:@"文件类型获取失败！" code:-1 userInfo:nil]);
        }
        return;
    }
    //如无文件名，生成时间戳作为文件名
    if (!name || name.length <= 0) {
        name = [NSString stringWithFormat:@"%f%@",[[NSDate date] timeIntervalSince1970],type];
    }
    
    if (!_manager) {
        _manager = [AFHTTPSessionManager manager];
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        [_manager.securityPolicy setValidatesDomainName:NO];
        _manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", @"text/json",@"text/plain", nil];
    }
    
    NSURLSessionDataTask *task = [[AFHTTPSessionManager manager] POST:@"http://172.16.11.223:9999/upload_file.php" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //这里的file需要和server保持一致
        [formData appendPartWithFileData:data name:@"file" fileName:name mimeType:type];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (WeUploadProgress) {
            WeUploadProgress(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject[@"code"] integerValue] == 200) {
            if (success) {
                success(responseObject);
            }
        }
        else {
            if (failure) {
                failure([NSError errorWithDomain:responseObject[@"msg"] code:[responseObject[@"code"] integerValue] userInfo:nil]);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
    [task resume];
}

@end

