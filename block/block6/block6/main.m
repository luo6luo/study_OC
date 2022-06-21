//
//  main.m
//  block6
//
//  Created by lg on 2022/6/21.
//

#import <Foundation/Foundation.h>
#import "DZRPerson.h"

typedef void(^DZRBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /**
         本节内容：__block本质
         
         __block修饰的内容，编译器会将其封装成一个结构体，原本需要存储的内容，现在存储在结构体的成员中
         所以最后block捕获的是结构体实例的地址
         执行block逻辑代码时，调用的是结构体的成员变量来修改值
         不管是基础数据类型，还是构造数据类型，都是上面这套流程
         
         具体代码，查看main.mm
         */
        __block DZRPerson *person = [[DZRPerson alloc] init];
        __block int age = 10;
        
        DZRBlock block = ^{
            person = nil;
            age = 20;
            
            NSLog(@"age: %d", age);
        };
        
        block();
        
        /**
         特别说明：
         此处访问的age，不是‘__block int age = 10;’中的age，是‘__block int age = 10;’转为为的结构体内部成员变量age
         */
        NSLog(@"age: %d", age);
    }
    return 0;
}
