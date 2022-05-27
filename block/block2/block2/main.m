//
//  main.m
//  block2
//
//  Created by lg on 2022/5/23.
//

#import <Foundation/Foundation.h>

int age = 10;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /**
         1、自动局部变量，修饰词auto
         
         系统默认的变量都是auto类型
         在栈中存储，作用域是在大括号内，用完会被释放销毁
         
         转成的c++代码：main_auto.cpp
         */
//        auto int age = 10;
//
//        void (^block)(void) = ^{
//            NSLog(@"age - %d", age);
//        };
//
//        age = 20;
//        block();
        
        /**
         2、静态局部变量，修饰词static
         
         在全局区存储，会一直存在，等程序结束时释放掉
         转成c++代码：main_static.cpp
         */
//        static int age = 10;
//
//        void (^block)(void) = ^{
//            NSLog(@"age: %d", age);
//        };
//
//        age = 20;
//        block();
        
        /**
         3、全局变量
         
         在全局区存储，会一直存在，等程序结束时释放掉
         转成c++代码：main_global.cpp
         */
        void (^block)(void) = ^{
            NSLog(@"age: %d", age);
        };
        
        age = 20;
        block();
    }
    return 0;
}
