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
         
         注意：只有对象类型的auto变量、__block修饰的变量，block捕获后，才会对他们进行内存管理
         
         __block修饰的内容，编译器会将其封装成一个结构体，原本需要存储的内容，现在存储在结构体的成员中
         所以最后block捕获的是结构体实例的地址
         执行block逻辑代码时，调用的是结构体的成员变量来修改值
         不管是基础数据类型，还是构造数据类型，如果被__block修饰，都是上面这套流程。
         值得注意的是，block被copy到堆区时，其实是把__block修饰的变量也拷贝到了堆区，而后我们访问的都是堆区的block和__block变量
         
         具体代码，查看main.mm
         */
        __block DZRPerson *person = [[DZRPerson alloc] init];
        __block int age = 10;
        
        NSLog(@"捕获前地址：%p", &age);
        
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
        
        
        /**
         输出结果：
         捕获前地址：0x7ff7bfeff318
         捕获后地址：0x101325228
         
         根据地址值，可知age已经从栈区到了堆区。
         
         原因：因为block在从栈区copy到堆区时，会调用 __main_block_copy_0 函数对age(此处说的age是被__block修饰后，转为的结构体，被block捕获的age)进行内存管理，会将age也copy一份到堆区。
         此时block访问的age是堆区的age，不是栈区的age。
         而不管是栈区还是堆区的age，再block被copy到堆区后，age的__forwarding，都是指向了堆区的age
         */
        NSLog(@"捕获后地址：%p", &age);
    }
    return 0;
}
