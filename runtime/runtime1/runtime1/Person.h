//
//  Person.h
//  runtime1
//
//  Created by lg on 2022/8/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

/**
 (数据类型和大小：https://blog.csdn.net/qq_36557133/article/details/107538568)
 此处定义两个属性，都是bool类型，各占位1个字节，8位二进制位，一共用了8个字节，64位。
 但是实际上每个属性只需要用1位就能存储所有信息，0:false 1:true。
 这样节约了内存，只需要一个字节就能存储信息，且还富余6位二进制位可以存储更多的bool对象。
 
 实现方式：重定义set、get方法，将所有值存到一个char类型(只占一个字节)的对象中。
 具体实现看Person.m
 
 方式二是isa在arm64之后的存储方式
 */
//@property (nonatomic, assign, getter=isHigh) BOOL high;
//@property (nonatomic, assign, getter=isRich) BOOL rich;

- (BOOL)isHigh;
- (BOOL)isRich;
- (void)setHigh: (BOOL)isHigh;
- (void)setRich: (BOOL)isRich;

@end

NS_ASSUME_NONNULL_END
