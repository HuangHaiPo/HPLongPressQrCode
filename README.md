# iOS 仿微信H5页面实现长按 识别二维码、保存图片功能

![效果](https://upload-images.jianshu.io/upload_images/1483397-ebf66a1b70ddb917.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

实现识别二维码可以通过截屏或者获取到图片的链接通过链接获得图片识别，不过通过截屏会有很多问题比如图片过小或者屏幕上有两个以上二维码，就识别不了。所以通过链接获取到图片对象识别二维码，是目前发现最好的方式。

#### 1、截屏
给网页加个长按手势，记得添加代理否则手势无法识别。
```
UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressDiscoverQrCode:)];
longTap.delegate = self;
longTap.minimumPressDuration = 0.5f;
[_webView addGestureRecognizer:longTap];

//是否支持多时候触发，返回YES，则可以多个手势一起触发方法，返回NO则为互斥
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
```
手势事件
```
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
```
保存图片

```
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
```
识别二维码

```
//识别二维码
- (void)scanQRCodeWithQRCodeImage:(UIImage *)aQRCodeImage{
    //利用CIDetector识别二维码 目前CIDetector还是很强大 有一些二维码识别不了 比如二维码对比不明显或者不是多清楚 或者跳转到APP Store 识别不了  所以最好还是用第三方 比如ZBar ZXing等
    //识别二维码
    /*CIDetector是Core Image框架中提供的一个识别类，包括对人脸、形状、条码、文本的识别，本文主要介绍二维码识别。
    今天主要看CIDetector对图片当中二维码的识别*/
    // CIDetector(CIDetector可用于人脸识别)进行图片解析，从而使我们可以便捷的从相册中获取到二维码
    // 声明一个 CIDetector，并设定识别类型 CIDetectorTypeQRCode
    CIImage *ciImage = [[CIImage alloc]initWithCGImage:aQRCodeImage.CGImage options:nil];
    //创建图形上下文
    CIContext *ciContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];//软件渲染
    //创建识别器对象 写入识别类型
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
```
识别器的几种类型
```
 // 人脸识别探测器类型
 其中人脸识别功能不单单可以对人脸进行获取，还可以获取眼睛和嘴等面部特征信息。但是CIDetector不包括面纹编码提取，也就是说CIDetector只能判断是不是人脸，而不能判断这张人脸是谁的，比如说面部打卡这种功能是实现不了的。
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeFace NS_AVAILABLE(10_7, 5_0);
//    // 矩形检测探测器类型
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeRectangle NS_AVAILABLE(10_10, 8_0);
//    // 条码检测探测器类型
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeQRCode NS_AVAILABLE(10_10, 8_0);
//    // 文本检测探测器类型
//#if __OBJC2__
//    CORE_IMAGE_EXPORT NSString* const CIDetectorTypeText NS_AVAILABLE(10_11, 9_0);
//#endif
```
#### 2 、通过链接获取图片识别

```
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
```
#### 关键点
我们获取到手指长按触点在H5界面的位置，再使用 JS 可以获取到该点显示的元素，这样就可以获取到`img`标签，拿到图片的地址。
```
NSString *js = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
NSString *imageUrl = [tempWebView stringByEvaluatingJavaScriptFromString:js];
```

##### 总结：
1. 截屏实现识别二维码槽点太多，不能用，就一个不能识别小点的二维码就直接pass了。
2. 通过链接获取图片识别对网速有点要求，如果图片过大网速不好可能会很慢，不过这些基本不是问题，不算是APP的问题。

