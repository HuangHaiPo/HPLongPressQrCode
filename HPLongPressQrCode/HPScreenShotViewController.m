//
//  HPScreenShotViewController.m
//  HPLongPressQrCode
//
//  Created by Leon on 2019/6/21.
//  Copyright © 2019 leon. All rights reserved.
//

#import "HPScreenShotViewController.h"
#import <SafariServices/SafariServices.h>

@interface HPScreenShotViewController ()<UIGestureRecognizerDelegate,UIWebViewDelegate>


@end

@implementation HPScreenShotViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //TODO:
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.pgyer.com/20lL"]]];
    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressDiscoverQrCode:)];
    longTap.delegate = self;
    longTap.minimumPressDuration = 0.5f;
    [_webView addGestureRecognizer:longTap];
//    longTap.cancelsTouchesInView = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}
//是否支持多时候触发，返回YES，则可以多个手势一起触发方法，返回NO则为互斥
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
- (void)longPressDiscoverQrCode:(UILongPressGestureRecognizer *)tap{
    //手势识别开始
    if (tap.state != UIGestureRecognizerStateBegan) {
        return;
    }
    //截图再读取 通过截屏识别二维码也不是特别靠谱 二维码多小 或者 屏幕上不止一个二维码 也识别不了 所以最好不要用截屏实现 这些是目前写遇到的问题 可以有别的更好的办法 来实现截屏识别二维码
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size,YES, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.view.layer renderInContext:context];
    
    UIImage *tempImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    __weak typeof(self)weakSelf = self;
    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *qrCodeAction = [UIAlertAction actionWithTitle:@"识别二维码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf scanQRCodeWithQRCodeImage:tempImage];
    }];
    UIAlertAction *saveImageAction = [UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf saveImageWithImg:tempImage];
    }];
    [alertCon addAction:cancelAction];
    [alertCon addAction:qrCodeAction];
    [alertCon addAction:saveImageAction];
    [self presentViewController:alertCon animated:YES completion:nil];
}
#pragma mark - 保存到相册
- (void)saveImageWithImg:(UIImage *)image{
    /**
     保存图片方法

     @param image 图片对象
     @param self 成功保存后回调对象 方法绑定的对象
     @param image:didFinishSavingWithError:contextInfo: 成功后调用方法
     @return 需要传递信息(成功后调用方法的参数)
     */
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = nil ;
    if(error){
        msg = @"保存图片失败" ;
    }else{
        msg = @"保存图片成功" ;
    }
}
//识别二维码
- (void)scanQRCodeWithQRCodeImage:(UIImage *)aQRCodeImage{
    //利用CIDetector识别二维码 目前CIDetector还是很强大 有一些二维码识别不了 比如二维码对比不明显或者不是多清楚 或者跳转到APP Store 识别不了  所以最好还是用第三方 比如ZBar ZXing等
    //识别二维码
    /*CIDetector是Core Image框架中提供的一个识别类，包括对人脸、形状、条码、文本的识别，本文主要介绍人脸特征识别。
    人脸识别功能不单单可以对人脸进行获取，还可以获取眼睛和嘴等面部特征信息。但是CIDetector不包括面纹编码提取，也就是说CIDetector只能判断是不是人脸，而不能判断这张人脸是谁的，比如说面部打卡这种功能是实现不了的。
    今天主要看CIDetector对图片当中二维码的识别*/
    // CIDetector(CIDetector可用于人脸识别)进行图片解析，从而使我们可以便捷的从相册中获取到二维码
    // 声明一个 CIDetector，并设定识别类型 CIDetectorTypeQRCode
    
    CIImage *ciImage = [[CIImage alloc]initWithCGImage:aQRCodeImage.CGImage options:nil];
    //创建图形上下文
    CIContext *ciContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];//软件渲染
    //创建识别器对象 写入识别类型
    // 人脸识别探测器类型
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeFace NS_AVAILABLE(10_7, 5_0);
//    // 矩形检测探测器类型
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeRectangle NS_AVAILABLE(10_10, 8_0);
//    // 条码检测探测器类型
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeQRCode NS_AVAILABLE(10_10, 8_0);
//    // 文本检测探测器类型
//#if __OBJC2__
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeText NS_AVAILABLE(10_11, 9_0);
//#endif
    //识别二维码
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:ciContext options:@{CIDetectorAccuracy :CIDetectorAccuracyHigh}];//二维码识别
    //取得识别结果
    NSArray *features = [detector featuresInImage:ciImage];

    for (CIQRCodeFeature *feature in features) {
        if ([feature.messageString containsString:@"http"]) {
            [self jumpSafariVcWithUrl:feature.messageString];
        }

    }
}
- (void)jumpSafariVcWithUrl:(NSString *)aUrl{
    NSLog(@"aUrl = %@",aUrl);//二维码中的信息
    //创建SafariVC 弹出SafariVC
    SFSafariViewController *sfVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:aUrl]];
    [self presentViewController:sfVC animated:YES completion:nil];
}
- (UIWebView *)webView{
    if (!_webView) {
        _webView = [[UIWebView alloc]init];
        _webView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        _webView.delegate = self;
        [self.view addSubview:_webView];
    }
    return _webView;
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
