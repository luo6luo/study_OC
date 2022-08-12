//
//  main.m
//  block-总结
//
//  Created by lg on 2022/8/8.
//
//  block总结

#import <Foundation/Foundation.h>
#import "Person.h"

// 3、全局变量捕获
int c = 30;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 1、基础类型auto变量捕获
        int a = 10;
        
        // 2、静态变量捕获
        static int b = 20;
        
        // 4、对象类型auto变量捕获
        Person *person = [[Person alloc] init];
        __weak typeof(person) weakPerson = person;
        __strong typeof(person) strongPerson = person;
        
        // 5、__block修饰基础数据类型
        __block int d = 20;
        
        // 6、__block修饰对象类型
        __block Person *blockPerson = person;
        
        // 简单结构的block，不涉及内存管理
        void (^block0)(void) = ^{
            NSLog(@"a:%d, b:%d, c:%d", a, b, c);
        };
        
        // 复杂结构的block，设计成员变量的内存管理
        void (^block1)(void) = ^{
            d = 22;
            blockPerson.age = 55;
            NSLog(@"a:%d, b:%d, c:%d, d:%d, age:%d", a, b, c, d, blockPerson.age);
            NSLog(@"weakPerson:%@, strongPerson:%@", weakPerson, strongPerson);
        };
        
        block0();
        block1();
        
        NSLog(@"a:%d, b:%d, c:%d, d:%d, age:%d", a, b, c, d, blockPerson.age);
        
    }
    return 0;
}
