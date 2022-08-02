//
//  Person.m
//  runtime1
//
//  Created by lg on 2022/8/1.
//

#import "Person.h"


/**
 << 左移多少位
 >> 右移多少位
 */
// 1：0b 0000 0001 将1左移0位
#define kHighMask (1<<0)
// 2：0b 0000 0010 将1左移1位
#define kRichMask (1<<1)

@interface Person()
{
    /**
     方式一：
     假设_data内容：0b 0000 0011(0b表示二进制)
     _data的最后一位表示high的值，倒数第二位表示rich的值。
     */
    char _data;
    
    /**
     方式二：
     方式一使用不够明确，这里使用共同体进一步理解使用
     这里给所有成员都只设置一位，且共用数据，共用体的内存大小，是最大成员内存大小
     (如果设置high = 1，那么打印rich，此时rich输出也是1，具体看共用体的说明)
     */
    union {
        // 占2位，存储high和rich，最后一位high，倒数第二位rich
        int bits;
        
        struct {
            char high : 1; // 只占一位
            char rich : 1; // 只占一位
        };
    } _data1;
}

@end

@implementation Person

- (BOOL)isHigh
{
    /**
     方式一：
     与运算：0&0 = 0；0&1 = 0；1&1 = 1；
     此处遇上掩码kHighMask后，只有最后一位保存，其他置0
     eg：0000 0011 & 0000 0001 = 0000 0001
     */
//    return _data & kHighMask;
    
    // 方式二：
    // 下面方法 = _data1.rich & kHighMask > 0
    return !!(_data1.bits & kHighMask);
}

- (BOOL)isRich
{
    /**
     方式一：
     此处遇上掩码kRighMask后，只有倒数第二位保存，其他置0
     eg：0000 0011 & 0000 0010 = 0000 0010
     */
//    return _data & kRichMask;
    
    // 方式二：
    // 下面方法 = _data1.rich & kRichMask > 0
    return !!(_data1.rich & kRichMask);
}

- (void)setHigh: (BOOL)isHigh
{
    /**
     方式一：
     或运算：0|0 = 0；0|1 = 1；1|1 = 1；
     位取反：~，所有位取反
     */
//    if (isHigh) {
//        // 0000 0011 | 0000 0001 = 0000 0011
//        _data |= kHighMask;
//    } else {
//        // 0000 0011 & 1111 1110 = 0000 0010
//        _data &= ~kHighMask;
//    }
    
    // 方式二：
    if (isHigh) {
        _data1.bits |= kHighMask;
    } else {
        _data1.bits &= ~kHighMask;
    }
}

- (void)setRich: (BOOL)isRich
{
    // 方式一：
//    if (isRich) {
//        // 0000 0011 | 0000 0010 = 0000 0011
//        _data |= kRichMask;
//    } else {
//        // 0000 0011 & 1111 1101 = 0000 0001
//        _data &= ~kRichMask;
//    }
    
    // 方式二：
    if (isRich) {
        _data1.bits |= kRichMask;
    } else {
        _data1.bits &= ~kRichMask;
    }
}

@end
