//
//  main.m
//  block7
//
//  Created by lg on 2022/7/22.
//
// block循环引用

#import <Foundation/Foundation.h>
#import "Person.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person *person = [[Person alloc] init];
//        person.block = ^() {
//            person.age = 10;
//        };
        /**
         打印结果：
         2022-07-22 18:07:29.759045+0800 block7[7426:968479] 111111
         
         上面的用法造成了循环引用，原因：
         1、person有一个属性block，person结构体中，有一个数组专门存放属性，所以person持有block
         2、因为person是auto类型局部变量，所以block捕获person是地址捕获，对person进行了一次retain
         3、这就造成了person持有block，block持有person，最后形成一个循环圈，无法释放内存
         */
        
        
        __weak typeof(person) weakPerson = person; // 等价于 __weak Person *weakPerson = person;
        __unsafe_unretained Person *unsafePerson = person;
        __block Person *blockPerson = person;
        person.block = ^() {
//            // 2022-07-22 18:08:31.723814+0800 block7[7898:970563] 111111
//            // 2022-07-22 18:08:31.724481+0800 block7[7898:970563] Person - dealloc
//            weakPerson.age = 10;
            
//            // 2022-07-22 18:09:06.860269+0800 block7[8148:971703] 111111
//            // 2022-07-22 18:09:06.860590+0800 block7[8148:971703] Person - dealloc
//            unsafePerson.age = 10;
            
//            // 2022-07-22 18:11:44.587761+0800 block7[9236:976065] 111111
//            // 2022-07-22 18:11:44.588071+0800 block7[9236:976065] Person - dealloc
//            blockPerson.age = 10;
//            blockPerson = nil;
        };
        person.block();
        NSLog(@"111111");
        
        /**
         上面三种方法都可以做到解除循环引用，现在分析下他们的优缺点
         1、__weak修饰person，使block在捕获person时，已弱引用持有，不会对person进行类似retain和release操作；
            当person释放后，会把weakPerson = nil，此时访问weakPerson，系统会直接返回，不会做其他操作。
         2、__unsafe_unretained修饰person，block也不会对person进行类似retain和release的操作；
            当person释放后，unsafePerson指针还会指向那块内存空间，但是实际上那块内存已经被释放调用，所以就出现了野指针，当再调用unsafePerson的话，就会崩溃。
         3、__block修饰perosn，会生成一个结构体，结构体内部强引用person，block捕获的是__block生成的结构体，和person无关；
            他们的持有关系是person --> block --> blockPerson --> person，这样一个循环关系；
            当person需要释放的时候，将其捕获的blockPerson置空，这个循环链就断开了，person就能被释放掉了；
         
         总结：__unsafe_unretained修饰可能会造成野指针；__block修饰需要手动置空对象；__weak是最合适的使用方式
         */
        
    }
    return 0;
}
