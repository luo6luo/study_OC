//
//  main.m
//  block0
//
//  Created by lg on 2022/7/22.
//
//  block的使用

#import <Foundation/Foundation.h>
#import "Person.h"

typedef int(^TypeBlock)(int a, int b);

void test0(int(^divBlock)(int a, int b)) {
    int div = divBlock(4, 2);
    NSLog(@"div: %d", div);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // 作为局部变量使用
        int(^mulBlock)(int a, int b) = ^(int a, int b) {
            return a * b;
        };
        int mul = mulBlock(2, 4);
        NSLog(@"mul: %d", mul);
        
        // block作为属性使用
        int sum = 0;
        Person *person = [[Person alloc] init];
        if (person.sumBlock) {
            sum = person.sumBlock(1, 2);
        }
        NSLog(@"sum: %d", sum);
        
        // 定义一种block类型，然后使用
        // 也可以作为属性：@property (nonatomic, coty) TypeBlock block;
        TypeBlock subBlock = ^(int a, int b) {
            return a - b;
        };
        int sub = subBlock(4, 2);
        NSLog(@"sub: %d", sub);
        
        // 作为参数使用
        test0(^int(int a, int b) {
            return a/b;
        });
        
        /**
         输出结果：
         2022-07-22 17:38:55.035306+0800 block0[95608:933073] mul: 8
         2022-07-22 17:38:55.035615+0800 block0[95608:933073] sumBlock
         2022-07-22 17:38:55.035650+0800 block0[95608:933073] sum: 3
         2022-07-22 17:38:55.035673+0800 block0[95608:933073] sub: 2
         2022-07-22 17:38:55.035693+0800 block0[95608:933073] div: 2
         2022-07-22 17:38:55.035712+0800 block0[95608:933073] Person -- dealloc
         */
    }
    return 0;
}
