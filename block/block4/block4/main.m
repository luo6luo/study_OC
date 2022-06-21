//
//  main.m
//  block4
//
//  Created by lg on 2022/6/20.
//

#import <Foundation/Foundation.h>

# pragma mark - copy操作

typedef void(^Block) (void);

Block myBlockFunc(void) {
    int a = 5;
    return ^{
        NSLog(@"a: %d", a);
    };
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // ARC环境下，哪些情况编辑器会对block进行copy操作
        
        /**
         1、block作为函数返回值
         
         输出结果：__NSMallocBlock__
         
         说明：
         myBlockFunc函数返回一个block，该block在myBlockFunc函数中，是一个局部变量，它在栈中，随时可能销毁，
         如果要函数外其他变量持有它，那么需要将其copy到堆中，所以编辑器会对其进行copy操作，
         */
        NSLog(@"%@", [myBlockFunc() class]);
        
        /**
         2、将block赋值给 __strong 指针
         
         输出结果：__NSMallocBlock__
         
         说明：__strong 是OC对象默认的修饰符，强引用是编辑器用于自动管理其引用计数使用
         下面代码等同：Block __strong myBlock = myBlockFunc();
         所以myBlock也是 __NSMallocBlock__ 类型的
         */
        Block myBlock = myBlockFunc();
        myBlock();
        NSLog(@"%@", [myBlock class]);
        
        /**
         3、在Cocoa API中，函数方法名有‘usingBlock’字样的，block作为其参数，编辑器会将该block进行copy操作
         
         下面函数中，void (NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx, BOOL *stop)这个block被进行了copy操作
         */
        NSArray *arr = @[@"1", @"2"];
        [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
        }];
        
        /**
         4、GCD方法中，block作为参数
         
         */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
        });
    }
    return 0;
}
