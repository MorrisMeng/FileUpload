//
//  WeUpload.h
//  UIImageControllerTest
//
//  Created by vhall on 2019/5/14.
//  Copyright © 2019 vhall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WeUpload : NSObject

/**
 *  iCloud文件上传
 *  documentsURL 文件地址；rename 文件重命名，文件名不需带文件类型后缀
 */
+ (void)uploadICloudFileWithUrl:(NSURL *)documentsURL
                         reName:(nullable NSString *)rename
                       progress:(nullable void (^)(NSProgress * progress))uploadProgress
                         sucess:(void(^)(NSDictionary *responseObject))uploadSuccess
                        failure:(void(^)(NSError *error))uploadFailure;

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
            failure:(void(^)(NSError *error))uploadFailure;

@end

NS_ASSUME_NONNULL_END
