//
//  ViewController.m
//  IsaAddress
//
//  Created by lg on 2022/8/5.
//

#import "ViewController.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 断点获取isa值
    UIViewController *vc = [[UIViewController alloc] init];
    NSLog(@"%p", [vc class]); // 类地址
    NSLog(@"%p", [UIViewController class]); // 类地址
    NSLog(@"%p", object_getClass([UIViewController class])); // 元类地址
    
    /**
     打印结果：
     [vc class]：0x1f2c578d0
     [UIViewController class]：0x1f2c578d0
     p/x vc->isa：$0 = 0x000025a1f2c578d5 UIViewController
     object_getClass([UIViewController class])：0x1f2c578f8
     */
}


@end
