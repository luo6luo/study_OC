//
//  ViewController.m
//  bitOperation
//
//  Created by lg on 2022/8/8.
//
//  位运算的实际操作

#import "ViewController.h"

/// 单选枚举
typedef NS_ENUM(NSInteger, SingleOption) {
    SingleOptionNone = 0,
    SingleOptionOne = 1,
    SingleOptionTwo = 2,
    SingleOptionThree = 3,
    SingleOptionFour = 4
};

/// 多选枚举
typedef NS_OPTIONS(NSInteger, MultiOptions) {
    MultiOptionsNone  /* = 1 0b0000 */ = 0,
    MultiOptionsOne   /* = 1 0b0001 */ = 1 << 0,
    MultiOptionsTwo   /* = 2 0b0010 */ = 1 << 2,
    MultiOptionsThree /* = 4 0b0100 */ = 1 << 3,
    MultiOptionsFour  /* = 8 0b1000 */ = 1 << 4,
};

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /**
     这种多类型的枚举实现方式，类比 MultiOptions
     */
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    
    /**
     options的值实际上是一个值，它是枚举内容相加所得：
        0b 0001 = MultiOptionsOne
      | 0b 0100 = MultiOptionsThree
      | 0b 1000 = MultiOptionsFour
     --------------------
        0b 1101 = options
     
     最后输出结果：
     2022-08-08 11:05:15.921984+0800 bitOperation[56453:172653] 获取到：MultiOptionsOne
     2022-08-08 11:05:15.922091+0800 bitOperation[56453:172653] 获取到：MultiOptionsOne
     2022-08-08 11:05:15.922170+0800 bitOperation[56453:172653] 获取到：MultiOptionsFour
     */
    MultiOptions options = MultiOptionsOne | MultiOptionsThree | MultiOptionsFour;
    [self getOptions:options];
}

/// 获取枚举值
- (void)getOptions:(MultiOptions)options
{
    // 此时的 options = 0b1101，需要获取这个值包含哪些枚举成员
    if (options & MultiOptionsOne) {
        /**
         eg：
           0b 1101
         & 0b 0001
         -----------
           0b 0001
         说明包含了 MultiOptionsOne
         */
        NSLog(@"获取到：MultiOptionsOne");
    }
    if (options & MultiOptionsTwo) {
        /**
         eg：
           0b 1101
         & 0b 0010
         -----------
           0b 0000
         说明不包含 MultiOptionsTwo
         */
        NSLog(@"获取到：MultiOptionsTwo");
    }
    if (options & MultiOptionsThree) {
        /**
         eg：
           0b 1101
         & 0b 0100
         -----------
           0b 0100
         说明包含了 MultiOptionsThree
         */
        NSLog(@"获取到：MultiOptionsOne");
    }
    if (options & MultiOptionsFour) {
        /**
           0b 1101
         & 0b 1000
         -----------
           0b 1000
         说明包含了 MultiOptionsFour
         */
        NSLog(@"获取到：MultiOptionsFour");
    }
}


@end
