//
//  main.m
//  block6
//
//  Created by lg on 2022/6/21.
//
//  __block本质

#import <Foundation/Foundation.h>
#import "DZRPerson.h"

typedef void(^DZRBlock)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /**
         注意：只有对象类型的auto变量，block捕获后，才会对他们进行内存管理
         
         总结：
         __block修饰的内容，编译器会将其封装成一个结构体S，原本需要存储的内容，现在存储在结构体的成员V中
         所以最后block捕获的是S的地址
         执行block逻辑代码时，调用的是结构体S的成员变量V的值
         不管是基础数据类型，还是对象类型，如果被__block修饰，都是上面这套流程。
         值得注意的是，block被copy到堆区时，其实是把__block修饰的变量也拷贝到了堆区，而后我们访问的都是堆区的block和__block变量
         
         关于内部的内存管理：
         1、block对于捕获变量的内存管理。当block从栈区copy到堆区时，
            a) 如果是__block修饰的变量，不管变量是基础数据类型、__strong对象类型、__weak对象类型，
               block对他们转换后的结构体，都会进行类似retain/release操作，是强引用；
            b) 如果不是__block修饰，同时是基础数据类型的变量，block不会对其进行额外内存管理处理；
            c) 如果不是__block修饰，同时是__strong修饰的对象类型变量，block对其是强引用，
               会对其进行类似retain/release操作；
            d) 如果不是__block修饰，同时是__weak修饰的对象类型变量，block不会对其进行额外内存管理处理；
         
         2、__block修饰的变量，转换为结构体后，其内部成员变量的内存管理。当__block变量的结构体(S)被copy到堆区时，
            a) 基础数据成员不会进行额外内存管理处理；
            b) __strong修饰的成员，会对其进行类似retain/release操作；
            c) __weak修饰的成员，不会对其进行额外内存管理处理；
         
         具体代码，查看main.mm
         */
        __block int age = 10;
        
        DZRPerson *person = [[DZRPerson alloc] init];
        __block DZRPerson *strongPerson = person;
        __block __weak DZRPerson *weakPerson = person;
        
        NSLog(@"捕获前地址：%p", &age);
        
        DZRBlock block = ^{
            NSLog(@"age: %d", age);
            NSLog(@"strong person: %@, weak person: %@", strongPerson, weakPerson);
        };
        
        block();
        
        /**
         特别说明：
         此处访问的age，不是‘__block int age = 10;’中的age，是‘__block int age = 10;’转为为的结构体内部成员变量age
         */
        NSLog(@"age: %d", age);
        
        
        /**
         输出结果：
         捕获前地址：0x7ff7bfeff318
         捕获后地址：0x101325228
         
         根据地址值，可知age已经从栈区到了堆区。
         
         原因：
         因为block在从栈区copy到堆区时，会调用 __main_block_copy_0 函数对age(此处说的age是被__block修饰后，转为的结构体，被block捕获的age)进行内存管理，会将age也copy一份到堆区。
         此时block访问的age是堆区的age，不是栈区的age。
         而不管是栈区还是堆区的age，再block被copy到堆区后，age的__forwarding，都是指向了堆区的age
         */
        NSLog(@"捕获后地址：%p", &age);
    }
    return 0;
}
