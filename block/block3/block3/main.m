//
//  main.m
//  block3
//
//  Created by lg on 2022/5/25.
//

#import <Foundation/Foundation.h>
#import "DZRTest.h"

# pragma mark - block的父类

void test1(void) {
    void (^block)(void) = ^{
        NSLog(@"block");
    };
    
    Class blockClass = [block class]; // __NSGlobalBlock__
    Class superClass = [blockClass superclass]; // NSBlock
    Class superSuperClass = [superClass superclass]; // NSObject
    Class superSuperSuperClass = [superSuperClass superclass]; // (null)
    
    /**
     打印结果：__NSGlobalBlock__ NSBlock NSObject (null)
     
     说明：block本质就是对象，所有block都是继承至NSBlock这个类，
          而NSBlock遵循OC对象原则，最后是继承至根类NSObject
     */
    NSLog(@"%@ %@ %@ %@", blockClass, superClass, superSuperClass, superSuperSuperClass);
}

# pragma mark - block的三种类型

void test2(void) {
    void (^block1)(void) = ^{
        NSLog(@"1");
    };
    
    int age = 10;
    void (^block2)(void) = ^{
        NSLog(@"age - %d", age);
    };
    
    /**
     打印结果：__NSGlobalBlock__ __NSMallocBlock__ __NSGlobalBlock__
     注意：main.m 通过命令行转为c++代码后，查看每个block结构体中，isa指针指向的不是下面三种类型。
          但是一起已运行时结果为准，通过命令行转换过来的文件，不一定准确
     
     说明：block一共有三种类型，分别是：
     1、__NSGlobalBlock__
     2、__NSMallocBlock__
     3、__NSStackBlock__
     
     内存分配简单介绍：
     iOS内存分为5个区域，下面地址由 低 -> 高
     1、代码区：我们的代码最终会以二进制形式，会存放在这个区域
     2、常量区：存放字符串，整个进程都在
     3、全局区：存放静态变量，全部变量，整个进程都在
     4、堆区：我们用 alloc、malloc 分配的空，这个区由程序员管理
     5、栈去：存放函数参数、局部变量、对象指针，由系统管理，随时可能销毁
     具体：https://juejin.cn/post/7009547605176745998
     
     __NSGlobalBlock__ 存放在：全局区
     __NSMallocBlock__ 存放在：堆区
     __NSStackBlock__  存放在：栈区域
     */
    NSLog(@"%@ %@ %@",[block1 class], [block2 class], [^{
        NSLog(@"%d", age);
    } class]);
}

# pragma mark - 三种block的出现情景

int count = 5;
void (^stackBlock2)(void);

void test(void) {
    int a = 200;
    stackBlock2 = ^{
        NSLog(@"a - %d", a);
    };
}

void test3(void) {
    /**
     注意：由于ARC环境下，编译器会帮我们做很多操作，无法看到最本质的内存情况，所以需要改为MRC环境下
     操作：Build Settings -> Automatic Reference Counting -> NO
     */
    
    // ------------- __NSGlobalBlock__ -------------
    void (^globalBlock0)(void) = ^{
        NSLog(@"global block");
    };
    
    static int num = 10;
    void (^globalBlock1)(void) = ^{
        NSLog(@"num - %d", num);
    };
    
    void (^globalBlock2)(void) = ^{
        NSLog(@"count - %d", count);
    };
    /**
     打印结果：__NSGlobalBlock__, __NSGlobalBlock__, __NSGlobalBlock__
     
     总结：没有访问auto类型局部变量的block，是__NSGlobalBlock__类型
          即便访问了static类型局部变量，全局变量，其类型还是__NSGlobalBlock__类型
     
     注意：其实这种类型block一般不用，因为没有意义，如果不需要访问局部变量，一般使用函数来调用代码块
     */
    NSLog(@"%@, %@, %@", [globalBlock0 class], [globalBlock1 class], [globalBlock2 class]);
    
    
    // ------------- __NSStackBlock__ -------------
    int b = 5;
    void (^stackBlock1)(void) = ^{
        NSLog(@"b - %d", b);
    };
    
    /**
     打印结果：__NSStackBlock__
     
     总结：访问了auto局部变量的block，是__NSStackBlock__类型
     */
    NSLog(@"%@", [stackBlock1 class]);
    
    
    /**
     打印结果：a - -1074793832
     
     思考问题：为什么捕获的a不是200
     原因：
     __NSStackBlock__，其所处的内存空间是栈区，但是栈区的特点是用完即销毁。
     此处首先调用test函数，而test函数内部，a是局部变量，存放在栈区；
     stackBlock2是一个全局变量，是一个指针，它指向这个block(简称B)，B是__NSStackBlock__类型，其实际分配的内存也在栈区。
     就算B进行了值捕获，将 a = 200 捕获到结构体内部，用a存储起来，但是在调用完test函数后，函数在栈区使用的空间就被释放了。
     此时再通过stackBlock2指针去调用原来B那块内存，就不知道会输出什么内容了，最后导致这个输出结果
     */
    test();
    stackBlock2();
    
    
    // ------------- __NSMallocBlock__ -------------
    void (^mallocBlock)(void) = [stackBlock1 copy];
    
    /**
     打印结果：__NSMallocBlock__
     总结：将__NSStackBlock__类型的block进行copy操作，就能将其内存搬到堆区，从而避免上面出现的问题
     */
    NSLog(@"%@", [mallocBlock class]);
    
    /**
     思考问题：如果将三种类型的block都进行copy操作，会发生什么喃
     
     打印结果：__NSGlobalBlock__, __NSMallocBlock__, __NSMallocBlock__
     总结：
     __NSGlobalBlock__进行copy后，还是__NSGlobalBlock__类型
     __NSStackBlock__进行copy后，变成了__NSMallocBlock__类型
     __NSMallocBlock__进行copy后，还是__NSMallocBlock__类型，但是block对象的引用计数+1了
     
     注意：ARC下，系统会自动帮我们把__NSStackBlock__类型的block进行copy操作
     */
    NSLog(@"%@, %@, %@", [[globalBlock0 copy] class], [[stackBlock1 copy] class], [[mallocBlock copy] class]);
    
    
}

# pragma mark - 查询所属内存区域

int aa = 10;
void test4(void) {
    int bb = 20;
    NSString *str = @"123";
   
    NSLog(@"全局区：%p", &aa);
    NSLog(@"常量区：%p", str);
    NSLog(@"栈区：%p", &bb);
    NSLog(@"堆区：%p", [[NSObject alloc] init]);
    NSLog(@"NSObject %p", [NSObject class]);
    NSLog(@"DZRTest %p", [DZRTest class]);
    
    /**
     输出结果：
     全局区：0x100008138
     常量区：0x100004298
     栈区：0x7ff7bfeff32c
     堆区：0x1041aa920
     NSObject 0x7ff852880030
     DZRTest 0x100008100
     
     可以看出
     NSObject类存储在栈区
     DZRTest类存储在数据段
     */
}

// block的类型
int main(int argc, const char * argv[]) {
    @autoreleasepool {
    
        // block本质是一个对象，继承至NSBlock
        test1();
        
        // block三种类型
        test2();
        
        // 哪种情况生成以上三种block
        test3();
        
        // 扩展补充知识
        test4();
    }
    return 0;
}


