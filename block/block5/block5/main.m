//
//  main.m
//  block5
//
//  Created by lg on 2022/6/20.
//

#import <Foundation/Foundation.h>
#import "DZRPerson.h"
#import "DZRStudent.h"

typedef void(^Block)(void);

/// 关于对象类型的auto变量，block是怎么进行捕获的
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Block block;
        {
            DZRPerson *person = [[DZRPerson alloc] init];
            person.age = 25;
            
            DZRStudent *student = [[DZRStudent alloc] init];
            student.age = 7;
            
            NSLog(@"1 person retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(person)));
            NSLog(@"1 student retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(student)));
            
            __weak DZRPerson *weakPerson = person;
            block = ^{
                NSLog(@"person age:%d, student age:%d", weakPerson.age, student.age);
            };
            
            NSLog(@"2 person retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(person)));
            NSLog(@"2 student retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(student)));
        }
        
        block();
        NSLog(@"--------");
        
        /**
         输出结果：
         2022-06-21 10:31:13.419083+0800 block5[39471:127961] 1 person retain count = 1
         2022-06-21 10:31:13.419476+0800 block5[39471:127961] 1 student retain count = 1
         2022-06-21 10:31:13.419516+0800 block5[39471:127961] 2 person retain count = 1
         2022-06-21 10:31:13.419540+0800 block5[39471:127961] 2 student retain count = 3
         2022-06-21 10:31:13.419561+0800 block5[39471:127961] dealloc - Person
         2022-06-21 10:31:13.419581+0800 block5[39471:127961] person age:0, student age:7
         2022-06-21 10:31:13.419600+0800 block5[39471:127961] --------
         2022-06-21 10:31:13.419628+0800 block5[39471:127961] dealloc - Student
         
         说明：
         此时block的类型是__NSMallocBlock__，是在堆上。因为它被__strong修饰的指针持有，所以进行了从栈区copy到了堆区。
         当前，block弱引用了person，强引用了student。person和student都是对象类型的auto变量，所以block都会捕获他们的值。
         block捕获他们后，他们的引用计数发生了变化，student引用计数为3，person还是为1。
         
         现将main.m转成c++文件，查看具体捕获情况
         终端输入：xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fobjc-arc -fobjc-runtime=ios-8.0.0 main.m
         注意：
         因为__weak修饰词需要用到iOS的运行时，而现在转译成c++，是静态编译，所以需要添加 -fobjc-arc -fobjc-runtime=ios-8.0.0，8.0.0是运行时版本
         
         捕获的person值是：DZRPerson *__weak weakPerson;
         OC对象默认修饰符是 __strong，所以main.cpp中，block捕获的student值是：DZRStudent *__strong student;
         
         block在从栈区copy到堆区时，调用内部的copy函数，将捕获的person、student根据他们的修饰符，进行类似retain操作。
         person修饰词__weak，不会进行类似retain操作；student修饰词__strong，会进行。
         
         当block从堆区释放时，会调用其内部dispose函数，然后将person、student进行类似release操作。
         person开始没有进行类似retain操作，此时不会进行类似release操作；student则会。
         
         所以person在超出的它的作用域后，就被销毁了，因为block没有对它进行类似retain操作，出了作用域，编辑器将它引用计数=0，即销毁。
         而student被block强引用，当前引用计数=3，即便出了作用域，student也不会销毁，要等待block从堆区移除，他的retainCount才=0。
         
         
         注意：
         以上结论是在ARC环境下进行的，将环境改为MRC后，再打印一次，结果：
         2022-06-21 10:40:04.556191+0800 block5[43026:139113] 1 person retain count = 1
         2022-06-21 10:40:04.556521+0800 block5[43026:139113] 1 student retain count = 1
         2022-06-21 10:40:04.556567+0800 block5[43026:139113] 2 person retain count = 1
         2022-06-21 10:40:04.556592+0800 block5[43026:139113] 2 student retain count = 1
         2022-06-21 10:40:04.556613+0800 block5[43026:139113] person age:25, student age:7
         2022-06-21 10:40:04.556633+0800 block5[43026:139113] --------
         
         说明MRC下，block不会对捕获变量进行类似retain和release操作，所有引用计数都是程序员手动操作，这也符合MRC的特性，手动管理内存。
         */
    }
    return 0;
}
