# FileUpload

实现文件上传功能，相册文件、拍照文件、iCloud文件上传。并搭建本地php服务调试上传功能。

## 一、搭建本地php环境

在本地搭建一个php服务，在iOS端进行图片、文件等上传测试。

## 二、上传文件

选取手机相册里的图片、拍照、选取iCloud里面的文件，进行上传。

```
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
```

[详情请参考](https://blog.csdn.net/Morris_/article/details/90212673)


