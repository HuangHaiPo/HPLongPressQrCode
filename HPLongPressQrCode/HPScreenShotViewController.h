//
//  HPScreenShotViewController.h
//  HPLongPressQrCode
//
//  Created by Leon on 2019/6/21.
//  Copyright © 2019 leon. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HPScreenShotViewController : UIViewController

@property (nonatomic ,strong) UIWebView *webView;


- (void) saveImageWithImg:(UIImage *)image;

- (void) jumpSafariVcWithUrl:(NSString *)aUrl;


@end

NS_ASSUME_NONNULL_END
