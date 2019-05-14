//
//  ViewController.m
//  UIImageControllerTest
//
//  Created by vhall on 2019/4/22.
//  Copyright © 2019 vhall. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import "MBProgressHUD.h"
#import "WeUpload.h"

@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIDocumentPickerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}
//拍照上传
- (IBAction)cameraBtnClick:(UIButton *)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

//相册
- (IBAction)photoAButtonAction:(UIButton *)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    //如果需要编辑图片，建议sourceType选择UIImagePickerControllerSourceTypeSavedPhotosAlbum，如果不需要，可选择UIImagePickerControllerSourceTypePhotoLibrary。
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}
//ICloud
- (IBAction)iCloudButtonAction:(UIButton *)sender {
    if (![ViewController ICloudEnable]) {
        NSLog(@"ICloud没有开启");
        return;
    }
    NSArray *documentTypes = @[@"public.content",
                               @"public.text",
                               @"public.source-code",
                               @"public.image",
                               @"public.jpeg",
                               @"public.png",
                               @"com.adobe.pdf",
                               @"com.apple.keynote.key",
                               @"com.microsoft.word.doc",
                               @"com.microsoft.excel.xls",
                               @"com.microsoft.powerpoint.ppt"];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeOpen];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UIImagePickerControllerDelegate
//selected
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //此处需要先dismiss掉picker，然后再present出alert，佛否则alert显示会出bug
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    //获取经过编辑后的图片
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        //如果未编辑，取原图
        image = info[UIImagePickerControllerOriginalImage];
    }
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum)
    {
        NSURL *url = nil;
        if (@available(iOS 11.0, *)) {
            url = info[UIImagePickerControllerImageURL];
        } else {
            url = info[UIImagePickerControllerReferenceURL];
        }
        [self selectedImage:image url:url reName:nil];
    }
    else if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        __block NSString *locolId = nil;
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //保存到相册
            PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            locolId = request.placeholderForCreatedAsset.localIdentifier;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error == nil) {
                //获取图片信息
                PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[locolId] options:nil];
                PHAsset *asset = [result firstObject];
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                    
                    NSURL *url = info[@"PHImageFileURLKey"];
                    [self selectedImage:image url:url reName:nil];
                }];
            }
            else {
                NSLog(@"图片保存失败!");
            }
        }];
    }
}
//cancel
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls
{
    [self selectedDocumentAtURLs:urls reName:nil];
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    [self selectedDocumentAtURLs:@[url] reName:nil];
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    CGFloat progress = totalBytesSent * 1.0 / totalBytesExpectedToSend;
    NSLog(@"上传进度:%f%%",progress*100);
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"上传完成! Error:%@",error);
}

#pragma mark - private
#pragma mark - private
+ (BOOL)ICloudEnable {
    NSURL *url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    return url != nil;
}
//相册/拍照文件上传
- (void)selectedImage:(UIImage *)image url:(NSURL *)url reName:(NSString *)name
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"是否上传此文档？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeCustomView;
        hud.label.text = @"努力上传中...";
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.progressTintColor = [UIColor redColor];
        progressView.trackTintColor = [UIColor redColor];
        hud.customView = progressView;
        
        [WeUpload uploadImage:image referenceURL:url reName:name progress:^(NSProgress * _Nonnull progress) {
            hud.progress  = progress.completedUnitCount * 1.0 / progress.totalUnitCount;
            NSLog(@"progress:%f",hud.progress);
        } sucess:^(NSDictionary * _Nonnull responseObject) {
            NSLog(@"responseObject:%@",responseObject);
            [MBProgressHUD hideHUDForView:self.view animated:NO];
        } failure:^(NSError * _Nonnull error) {
            [MBProgressHUD hideHUDForView:self.view animated:NO];
            NSLog(@"上传失败！%@",error);
        }];
    }];
    [alert addAction:cancel];
    [alert addAction:action];
    [self presentViewController:alert animated:NO completion:nil];
}
//iCloud文件上传
- (void)selectedDocumentAtURLs:(NSArray <NSURL *>*)urls reName:(NSString *)rename
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"是否上传此文档？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        for (NSURL *url in urls) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeCustomView;
            hud.label.text = @"努力上传中...";
            UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            progressView.progressTintColor = [UIColor redColor];
            progressView.trackTintColor = [UIColor whiteColor];
            hud.customView = progressView;
            
            [WeUpload uploadICloudFileWithUrl:url reName:rename progress:^(NSProgress * _Nonnull progress) {
                hud.progress  = progress.completedUnitCount / (1.0 * progress.totalUnitCount);
                NSLog(@"progress:%f",hud.progress);
            } sucess:^(NSDictionary * _Nonnull responseObject) {
                [MBProgressHUD hideHUDForView:self.view animated:NO];
            } failure:^(NSError * _Nonnull error) {
                [MBProgressHUD hideHUDForView:self.view animated:NO];
                NSLog(@"上传失败！%@",error);
            }];
        }
    }];
    [alert addAction:cancel];
    [alert addAction:action];
    [self presentViewController:alert animated:NO completion:nil];
}

@end
