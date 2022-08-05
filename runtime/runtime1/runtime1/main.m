//
//  main.m
//  runtime1
//
//  Created by lg on 2022/7/27.
//
//  isa指针实现原理

#import <Foundation/Foundation.h>
#import "Person.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /**
         每个类实际上都是一个结构体，且都包含一个isa成员。
         通过isa指针，对象能找到类对象，类可以找到元类。
         但是isa指针不是直接指向类/元类，而是通过 &mask(掩码) 来指向类/元类。
         这其中涉及到几个知识点：
         1、位域(https://www.runoob.com/cprogramming/c-bit-fields.html)，可为变量是指几位二进制。
         2、位运算(https://www.runoob.com/w3cnote/bit-operation.html)，&(与)、|(或)、<<(左移x位)、>>(右移x位)、~(位取反)。
         3、结构体大小计算(https://www.runoob.com/w3cnote/struct-size.html)，为最大成员大小整数倍。
         4、共同体(https://www.runoob.com/cprogramming/c-unions.html)，相同位置存储不同数据类型，拥有多成员，但是同时只能有一个成员有值，值共享。
            
         isa & mask 过程原理，用person这个例子说明
         */
        Person *person = [[Person alloc] init];
        person.high = NO;
        person.rich = YES;
        NSLog(@"high:%d rich:%d", person.isHigh, person.isRich);
        
        /**
         查看runtime源码可知，isa的类型是一个共同体(union)
         但是不同架构，isa_t内容也不同，下面是截取的arm64架构下简化后获得的内容
         
         isa_t isa;
         union isa_t {
             uintptr_t bits;
             struct {
                 uintptr_t nonpointer        : 1;                                       \
                 uintptr_t has_assoc         : 1;                                       \
                 uintptr_t has_cxx_dtor      : 1;                                       \
                 uintptr_t shiftcls          : 33; // MACH_VM_MAX_ADDRESS 0x1000000000  \
                 uintptr_t magic             : 6;                                       \
                 uintptr_t weakly_referenced : 1;                                       \
                 uintptr_t unused            : 1;                                       \
                 uintptr_t has_sidetable_rc  : 1;                                       \
                 uintptr_t extra_rc          : 19;  // defined in isa.h
             };
         };
         
         nonpointer：0，代表普通的指针，存储着Class、Meta-Class对象的内存地址；1，代表优化过，使用位域存储更多的信息。
         has_assoc：是否有设置过关联对象，如果没有，释放时会更快。
         has_cxx_dtor：是否有C++的析构函数（.cxx_destruct），如果没有，释放时会更快。
         shiftcls：存储着Class、Meta-Class对象的内存地址信息。
         magic：用于在调试时分辨对象是否未完成初始化。
         weakly_referenced：是否有被弱引用指向过，如果没有，释放时会更快。
         unused：未使用的。
         has_sidetable_rc：引用计数器是否过大无法存储在isa中。如果为1，那么引用计数会存储在一个叫SideTable的类的属性中。
         extra_rc：里面存储的值是引用计数器减1。
         
         上面的结构和刚刚分析过的 person 存储数据的方式二是一样的。
         isa在arm64之前，是一个普通的指针占8个字节，存储类/元类对象的内存地址。
         在arm64之后，对isa进行了优化，它还是占8个字节共64位，但是他存了很多内容，上面的结构体中存储的就是isa指针存储的所有内容。
         其中 shiftcls 占用33位，此成员才是真正存储类/元类内存地址的。
         
         问题：为什么使用时，在获取类/元类内存地址时，系统是 &mask
         因为isa经过优化后，不单单存储类/元类的内存地址，还存了很多其他内容，其中只有33位才是存储的类/元类地址。
         根据刚刚person.m分析，想要获取isa64位中某33位数据，需要利用 & 位运算进行处理取值。
         不同的架构，isa取值的掩码不同，arm64中掩码：define ISA_MASK 0x0000000ffffffff8ULL。
         将 ISA_MASK 进行二进制转换: 0000 0000 0000 0000 0000 0000 0000 1111 ，可以看出，ISA_MASK正好是33位。
                                  1111 1111 1111 1111 1111 1111 1111 1000
         
         这里单独说明：假设一个值，我们想要获取中间四位(此处是1001)，我们&00111100，获取到的值其实是100100，而不是1001，如下：
           0010 0100
         & 0011 1100
         ------------
           0010 0100
         
         由此可知，isa & ISA_MASK后，获取的值，最后三位一定是0，因为根据ISA_MASK转换的二进制可知，
         从高位到低位，其取的isa64位中，下标为 35 ~ 3 位的内容，最后三位存放的是其他内容，并没有获取。
         所以类/元类实际地址是，isa64位的35~3位 + 尾部三个0。
         eg: 根据IsaAddress中打印信息
         isa指针：0x000025a1f2c578d5，vc类地址：0x1f2c578d0，UIViewController元类地址：0x1f2c578f8
         
          0000 0000 0000 0000 0010 0101 1010 0001 1111 0010 1100 0101 0111 1000 1101 0101 = 0x000025a1f2c578d5
          0000 0000 0000 0000 0000 0000 0000 1111 1111 1111 1111 1111 1111 1111 1111 1000 = 0x0000000ffffffff8ULL
         ---------------------------------------------------------------------------------
          0000 0000 0000 0000 0000 0000 0000 0001 1111 0010 1100 0101 0111 1000 1101 0000 = 0x1f2c578d0
         
         可以看出 isa & ISA_MASK = 类/元类地址。
         类/元类尾部：0或者8，即0000或1000，所以最后三位是0。
         
         
         总结：
         1、类或元类的地址值后三位永远是0。
         2、为什么isa要&mask，因为arm64后，isa进行了优化，里面只有33位是拿来存放类/元类地址值，且存放位置是在中间，只有&mask才能取出对应的地址值，再加上后三位0，就是完整的类/元类地址值。
         3、在arm64之前，isa只是个普通的指针，它存储着类/元类对象的地址值；arm64之后，isa进行了优化，它使用共用体这种结构，存储着64位信息，其中只有33位是存储的类/元类地址。
         4、(有符号)-1和(无符号)255都是0xff。
         */
    }
    return 0;
}
