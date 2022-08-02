//
//  main.m
//  runtime1
//
//  Created by lg on 2022/7/27.
//
//  isa指针实现原理

#import <Foundation/Foundation.h>
#import "Person.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /**
         每个类实际上都是一个结构体，且都包含一个isa成员。
         通过isa指针，对象能找到类对象，类可以找到元类。
         但是isa指针不是直接指向类/元类，而是通过 &mask(掩码) 来指向类/元类。
         这其中涉及到几个知识点：
         1、位域(https://www.runoob.com/cprogramming/c-bit-fields.html)，可为变量是指几位二进制。
         2、位运算(https://www.runoob.com/w3cnote/bit-operation.html)，&(与)、|(或)、<<(左移x位)、>>(右移x位)、~(位取反)。
         3、结构体大小计算(https://www.runoob.com/w3cnote/struct-size.html)，为最大成员大小整数倍。
         4、共同体(https://www.runoob.com/cprogramming/c-unions.html)，相同位置存储不同数据类型，拥有多成员，但是同时只能有一个成员有值，值共享。
            
        
         查看runtime源码可知，isa的类型是一个共同体(union)
         union isa_t {
            ...
         }
         isa_t isa;
         
         isa & mask 过程原理和person这个例子有相同处
         */
        Person *person = [[Person alloc] init];
        person.high = NO;
        person.rich = YES;
        NSLog(@"high:%d rich:%d", person.isHigh, person.isRich);
    }
    return 0;
}
