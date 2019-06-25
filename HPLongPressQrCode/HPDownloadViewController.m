//
//  HPDownloadViewController.m
//  HPLongPressQrCode
//
//  Created by Leon on 2019/6/21.
//  Copyright © 2019 leon. All rights reserved.
//

#import "HPDownloadViewController.h"
#import "ZBarReaderController.h"


@interface HPDownloadViewController ()<UIGestureRecognizerDelegate>

@end

@implementation HPDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}
- (void)longPressDiscoverQrCode:(UILongPressGestureRecognizer *)tap{
    //手势识别开始
    if (tap.state != UIGestureRecognizerStateBegan) {
        return;
    }
    UIWebView *tempWebView = (UIWebView *)self.webView;
    CGPoint touchPoint = [tap locationInView:tempWebView];
    //关键在这 通过坐标 获取到点击图片的链接 通过链接下载或者识别二维码 目前是最好的
    NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    NSString *imageUrl = [tempWebView stringByEvaluatingJavaScriptFromString:js];
    if (imageUrl.length == 0) {
        return;
    }
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
    UIImage *tempImage = [UIImage imageWithData:data];
    CGImageRef cgImageRef = tempImage.CGImage;
    
    if (cgImageRef) {
        //save image or Extract QR code
        ZBarReaderController* read = [ZBarReaderController new];
        ZBarSymbol* symbol = nil;
        for(symbol in  [read scanImage:cgImageRef])
            break;
        if (symbol.data.length > 0) {
            if ([symbol.data containsString:@"http"]) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
                __weak typeof(self)weakSelf = self;

                UIAlertAction *qrCodeAction = [UIAlertAction actionWithTitle:@"识别二维码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakSelf jumpSafariVcWithUrl:symbol.data];
                }];
                UIAlertAction *saveImageAction = [UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakSelf saveImageWithImg:tempImage];
                }];
                [alertController addAction:cancelAction];
                [alertController addAction:qrCodeAction];
                [alertController addAction:saveImageAction];
                [self presentViewController:alertController animated:YES completion:nil];
                
            }
        }
    }
}
//是否支持多时候触发，返回YES，则可以多个手势一起触发方法，返回NO则为互斥
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
