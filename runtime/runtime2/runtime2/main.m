//
//  main.m
//  runtime2
//
//  Created by lg on 2022/8/17.
//
//  类、方法的底层结构认识
//  参考资料：
//  官方文档：https://developer.apple.com/documentation/objectivec/1418629-object_getclass?language=objc
//          https://developer.apple.com/documentation/objectivec/class?language=objc

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Person.h"
#import "Student.h"

void printC(char *type,char *c)
{
    NSLog(@"%s: %s\n",type, c);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
# pragma mark - objc_class 结构
        /**
         一、查看runtime源码：
         根据官网文档：
         // An opaque type that represents an Objective-C class.
         typedef struct objc_class *Class;
         
         // Returns the class of an object.
         Class object_getClass(id obj);
         
         总结：所有类都可以用Class来表示类型，
         
         查看runtime源码，Class本质就是一个结构体：objc_class
         /// An opaque type that represents an Objective-C class.
         typedef struct objc_class *Class;
         
         二、查看 objc_class
         // objc_class 继承 objc_object
         struct objc_object {
             Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
         };
         
         结构体简化内容：
         struct objc_class : objc_object {
            // Class ISA;
            Class superclass;
            cache_t cache;             // formerly cache pointer and vtable
            class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags
         
            class_rw_t *data() const {
                return bits.data();
            }
            void setData(class_rw_t *newData) {
                bits.setData(newData);
            }
         }
         
         // 查看 class_data_bits_t 结构体，bits & FAST_DATA_MASK = class_rw_t
         // 说明 bits 包含很多信息，和isa一样，&FAST_DATA_MASK 只是为了取其中存储的 class_rw_t 地址
         struct class_data_bits_t {
            class_rw_t* data() const {
                return (class_rw_t *)(bits & FAST_DATA_MASK);
            }
         }
         
         三、查看 class_rw_t 结构体简化，rw = readWrite 可读可写，它里面即存了类的信息，又添加了该类的分类信息
         struct class_rw_t {
            uint32_t flags;
            uint16_t witness;
         
            void set_ro(const class_ro_t *ro) {
                auto v = get_ro_or_rwe();
                if (v.is<class_rw_ext_t *>()) {
                    v.get<class_rw_ext_t *>(&ro_or_rw_ext)->ro = ro;
                } else {
                    set_ro_or_rwe(ro);
                }
            }
         
            // const class_ro_t *ro
            // class_ro_t 存放类初始信息
            const class_ro_t *ro() const {
                auto v = get_ro_or_rwe();
                if (slowpath(v.is<class_rw_ext_t *>())) {
                    return v.get<class_rw_ext_t *>(&ro_or_rw_ext)->ro;
                }
                return v.get<const class_ro_t *>(&ro_or_rw_ext);
            }
         
            // const method_array_t methods
            // 二位数组，存放 method_list_t，list存放 method_t
            const method_array_t methods() const {
                auto v = get_ro_or_rwe();
                if (v.is<class_rw_ext_t *>()) {
                    return v.get<class_rw_ext_t *>(&ro_or_rw_ext)->methods;
                } else {
                    return method_array_t{v.get<const class_ro_t *>(&ro_or_rw_ext)->baseMethods()};
                }
            }
         
            // const property_array_t properties
            // 二位数组，存放 property_list_t，list存放 property_t
            const property_array_t properties() const {
                auto v = get_ro_or_rwe();
                if (v.is<class_rw_ext_t *>()) {
                    return v.get<class_rw_ext_t *>(&ro_or_rw_ext)->properties;
                } else {
                    return property_array_t{v.get<const class_ro_t *>(&ro_or_rw_ext)->baseProperties};
                }
            }
         
            // const protocol_array_t protocols
            // 二位数组，存放 protocol_list_t，list存放 protocol_t
            const protocol_array_t protocols() const {
                auto v = get_ro_or_rwe();
                if (v.is<class_rw_ext_t *>()) {
                    return v.get<class_rw_ext_t *>(&ro_or_rw_ext)->protocols;
                } else {
                    return protocol_array_t{v.get<const class_ro_t *>(&ro_or_rw_ext)->baseProtocols};
                }
            }
         }
         
         四、查看 class_ro_t 结构体简化，此结构体是 onlyRead 只读，是类一开始就存放了信息，不能修改
         struct class_ro_t {
            uint32_t flags;
            uint32_t instanceStart;
            uint32_t instanceSize;
         
            // 这些都是类一开始存放的信息
            protocol_list_t * baseProtocols; // 协议列表
            const ivar_list_t * ivars; // 成员变量列表
            property_list_t *baseProperties; // 属性列表
            void *baseMethodList; // 方法列表
            method_list_t *baseMethods() const {
                return (method_list_t *)baseMethodList;
            }
         }
         
         *注意：以 method 为例，method_array_t 中存放 method_list_t，method_list_t 中存放的 method_t。
               所以不管是 method_array_t 还是 method_list_t，他们最终存放的都是 method_t。
               同理可得 property_t、protocol_t。
         
         五、以 method_t 为例，查看其简化结构体
         struct method_t {
            struct big {
                SEL name; // 选择器 - 函数名称，底层和char*类似
                const char *types; // 编码，包含函数的返回值类型、参数类型
                MethodListIMP imp; // 函数实现地址
            };
         }
         IMP函数具体实现：typedef id _Nullable (*IMP)(id _Nonnull, SEL _Nonnull, ...);
         
         
         总结：类开始加载时候，他的初始化信息(方法、属性、协议、成员变量)是存在 class_ro_t *ro 中，存放在 bits 中
         等编译时候，就动态的解析分类，将ro的信息和分类的信息一起存放到 class_rw_t 中，并rw替换ro存放到了 bits 中
         */
        NSObject *objc = [[NSObject alloc] init];
        
# pragma mark - method_t 结构
        // ----------------- method_t 具体内容分析 ---------------------
        
        /**
         一、SEL name，SEL 分析
         SEL 选择器，表示函数名称
         
         SEL的创建方法
         1、@selector
         2、NSSelectorFromString
         3、sel_registerName
         
         打印结果：
         SEL1:test SEL2:test SEL3:test
         SEL1:0x7ff81e1904c9 SEL2:0x7ff81e1904c9 SEL3:0x7ff81e1904c9
         
         总结：只要函数名称一样，他们的选择器就是一样的
         */
        Person *person = [[Person alloc] init];
        SEL sel1 = NSSelectorFromString(@"test");
        SEL sel2 = sel_registerName("test");
        SEL sel3 = @selector(test);
        NSLog(@"SEL1:%s SEL2:%s SEL3:%s", sel1, sel2, sel3);
        NSLog(@"SEL1:%p SEL2:%p SEL3:%p", sel1, sel2, sel3);
        
        /**
         二、const char *types，types 分析
         types是一个字符串，包含函数的返回类型、参数类型的编码(Type Encoding)。
         可以通过 @encode 将类型转换为对应的编码字符串，下面是对应的编码
         
         输出结果：
         char: c
         int: i
         short: s
         long: q
         long long: q
         unsigned char: C
         unsigned int: I
         unsigned short: S
         unsigned long: Q
         unsigned long long: Q
         float: f
         double: d
         BOOL: c
         void: v
         id: @
         Class: #
         SEL: :
         */
        printC("char", @encode(char));
        printC("int", @encode(int));
        printC("short", @encode(short));
        printC("long", @encode(long));
        printC("long long", @encode(long long));
        printC("unsigned char", @encode(unsigned char));
        printC("unsigned int", @encode(unsigned int));
        printC("unsigned short", @encode(unsigned short));
        printC("unsigned long", @encode(unsigned long));
        printC("unsigned long long", @encode(unsigned long long));
        printC("float", @encode(float));
        printC("double", @encode(double));
        printC("BOOL", @encode(BOOL));
        printC("void", @encode(void));
        printC("id", @encode(id));
        printC("Class", @encode(Class));
        printC("SEL", @encode(SEL));
        
        /**
         下面我们来分析下 types 在 method_t 中具体代表的意思
         特别说明：每个方法都默认隐藏了两个参数 id self, SEL _cmd
         
         方法: - (void)test
              - (void)test:(id)self _cmd:(SEL)_cmd
         types: v16@0:8 = v 16 @ 0 : 8
         说明: v  - 返回值，void
              16 - 这个方法一共需要16个字节
              @  - 隐藏参数一类型，id，id类型8个字节
              0  - 参数一(self)从第0个字节开始
              :  - 隐藏参数二类型，SEL，SEL类型8个字节，SEL类似char*，是个指针类型
              8  - 参数二(_cmd)从第8个字节开始
         总结: 该函数返回类型是void，一共有2个参数，id类型8字节，char*类型8字节，一共需要16个字节。
              self从第0个字节开始，共占8字节，_cmd挨着self，从第8个字节开始，共占8字节。
         
         方法: - (char *)types:(int)a with:(char *)b with:(float)c
         types: *32@0:8i16*20f28  =  * 32 @0 :8 i16 *20 f28
         说明: *  - 返回值类型，指针类型，此处是char*
              32 - 一共需要32个字节
              @  - 隐藏参数一类型，id，id类型8个字节
              0  - 参数一(self)从第0个字节开始
              :  - 隐藏参数二类型，SEL，SEL类型8个字节
              8  - 参数二(_cmd)从第8个字节开始
              i  - 参数三类型，int，int类型4个字节
              16 - 参数三(a)从第8+8=16个字节开始
              *  - 参数四类型，char*，char*类型8个字节
              20 - 参数四(b)从第16+4=20个字节开始
              f  - 参数五类型，float，float类型4个字节
              28 - 参数五(c)从第20+8=28个字节开始
         总结: 该函数返回类型是char*，一共有五个参数，其中有2个是隐藏参数，
              类型分别是id(8字节)、SEL(8字节)、int(4字节)、char*(8字节)、float(4字节)，由于对其原则，一共需要32字节。
              -----------------------------------------------------------------------------------------
                                                    一共需要32字节
              id:self(占8字节) -- SEL:_cmd(占8字节) -- int:a(占4字节) -- char*:b(占8字节) -- float:c(占4字节)
              index = 0          index = 8           index = 16       index = 20         index = 28
              -----------------------------------------------------------------------------------------
         */
        
        // 确认字节数
        // char*:8 int:4  id:8  float:4  SEL:8
        NSLog(@"char*:%lu  int:%lu  id:%lu  float:%lu  SEL:%lu", sizeof(char *), sizeof(int), sizeof(id), sizeof(float), sizeof(SEL));
        
        Class personClass = object_getClass(person); // 获取person的类
        Method method1 = class_getInstanceMethod(personClass, @selector(test)); // 获取类中指定的“test”方法
        struct objc_method_description *des1 = method_getDescription(method1); // 获取方法的参数类型的字符串
        NSLog(@"%s", des1->types); // 输出结果：v16@0:8
        
        Method method2 = class_getInstanceMethod(personClass, @selector(types:with:with:));
        struct objc_method_description *des2 = method_getDescription(method2);
        NSLog(@"%s", des2->types); // 输出结果：*32@0:8i16*20f28
    }
    return 0;
}
