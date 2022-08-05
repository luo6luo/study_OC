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

//// 方式一
//@interface Person()
//{
//    /**
//     假设_data内容：0b 0000 0011(0b表示二进制)
//     _data的最后一位表示high的值，倒数第二位表示rich的值，此时high = 1，rich = 1
//     */
//    char _data;
//}
//
//@end
//
//@implementation Person
//
//- (BOOL)isHigh
//{
//    /**
//     与运算：0&0 = 0；0&1 = 0；1&1 = 1；
//     此处与上掩码 kHighMask 后，只有最后一位保存，其他置0
//     eg:  0000 0011
//        & 0000 0001 = kHighMask
//       ---------------
//          0000 0001 = 1
//
//     注意：此处 !() 是转换为bool类型的一种简写，值非0则为YES。
//     */
//    return !!(_data & kHighMask);
//}
//
//- (BOOL)isRich
//{
//    /**
//     此处与上掩码 kRighMask 后，只有倒数第二位保存，其他置0
//     eg:  0000 0011
//        & 0000 0010 = kRichMask
//     ------------------
//          0000 0010 = 2
//     */
//    return !!(_data & kRichMask);
//}
//
//- (void)setHigh: (BOOL)isHigh
//{
//    /**
//     或运算：0|0 = 0；0|1 = 1；1|1 = 1；
//     位取反：~，所有位取反
//     */
//    if (isHigh) {
//        /**
//         eg: 当isHigh = YES
//            0000 0011
//          | 0000 0001 = kHighMask
//        ------------------
//            0000 0011 = _data
//         */
//        _data |= kHighMask;
//    } else {
//        /**
//         eg: 当isHigh = NO
//            0000 0011
//          & 1111 1110 = ~kHighMask
//        ------------------
//            0000 0010 = _data
//         */
//        _data &= ~kHighMask;
//    }
//}
//
//- (void)setRich: (BOOL)isRich
//{
//    if (isRich) {
//        /**
//         eg: 当isRich = YES
//            0000 0011
//          | 0000 0010 = kRichMask
//        ------------------
//            0000 0011 = _data
//         */
//        _data |= kRichMask;
//    } else {
//        /**
//         eg: 当isRich = NO
//            0000 0011
//          & 1111 1101 = ~kRichMask
//        ------------------
//            0000 0001 = _data
//         */
//        _data &= ~kRichMask;
//    }
//}

// 方式二
@interface Person()
{
    /**
     方式一使用不够明确，high、rich没有明确的标记，时间久后容易遗忘，这里使用共同体进一步优化，给所有成员都只设置一位，这样能够用最小的内存空间存储多内容，并且能够直观的产看内存中有哪些成员变量，不像方式一，虽然节约了空间，但是看不到内部有哪些成员变量。
     
     共用体的内存大小，是最大成员内存大小，并且不管成员是什么类型，输出的结果都是一样的，因为共用体相当于是用一块内存存储一个值
     (如果设置high = 1，那么打印rich，此时rich输出也是1，具体看共用体的说明)
     */
    union {
        // char占1个字节共8位，存储high和rich，最后一位high，倒数第二位rich
        // 设计思想：此公用体的所有数据都存储在bits里面，它的内存大小就是1个字节共8位，8位里面存储所有数据
        // 此处假设 bits = 0b 0000 0011
        char bits;

        struct {
            char high : 1; // 只占一位
            char rich : 1; // 只占一位
        };
    } _data;
}

@end

@implementation Person

- (BOOL)isHigh
{
    /**
     eg:  0000 0011
        & 0000 0001 = kHighMask
        ---------------
          0000 0001 = 1
     */
    return !!(_data.bits & kHighMask);
}

- (BOOL)isRich
{
    /**
     eg:  0000 0011
        & 0000 0010 = kRichMask
        ---------------
          0000 0010 = 2
     */
    return !!(_data.rich & kRichMask);
}

- (void)setHigh: (BOOL)isHigh
{
    if (isHigh) {
        /**
         eg: 当isHigh = YES
             0000 0011
           | 0000 0001 = kHighMask
         ------------------
             0000 0011 = _data.bits
         */
        _data.bits |= kHighMask;
    } else {
        /**
         eg: 当isHigh = NO
             0000 0011
           & 1111 1110 = ~kHighMask
         ------------------
             0000 0010 = _data.bits
         */
        _data.bits &= ~kHighMask;
    }
}

- (void)setRich: (BOOL)isRich
{
    if (isRich) {
        /**
         eg: 当isRich = YES
            0000 0011
          | 0000 0010 = kRichMask
         ------------------
            0000 0011 = _data.bits
         */
        _data.bits |= kRichMask;
    } else {
        /**
         eg: 当isRich = NO
             0000 0011
           & 1111 1101 = ~kRichMask
         ------------------
             0000 0001 = _data.bits
         */
        _data.bits &= ~kRichMask;
    }
}


@end
