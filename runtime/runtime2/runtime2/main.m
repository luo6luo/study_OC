//
//  main.m
//  runtime2
//
//  Created by lg on 2022/8/17.
//
//  类、方法的底层结构认识

#import <Foundation/Foundation.h>
#import "Person.h"
#import "Student.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /**
         一、查看runtime源码：
         /// An opaque type that represents an Objective-C class.
         typedef struct objc_class *Class;
         
         所有类都可以用Class来表示类型，根据runtime源码可知，类底层就是一个结构体：objc_class
         
         二、查看 objc_class 结构体简化内容：
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
                const char *types; // 包含函数的返回值、参数编码的字符串
                MethodListIMP imp; // 函数实现地址
            };
         }
         IMP函数具体实现：typedef id _Nullable (*IMP)(id _Nonnull, SEL _Nonnull, ...);
         
         
         总结：类开始加载时候，他的初始化信息(方法、属性、协议、成员变量)是存在 class_ro_t *ro 中，存放在 bits 中
         等编译时候，就动态的解析分类，将ro的信息和分类的信息一起存放到 class_rw_t 中，并替换ro存放到了 bits 中
         */
        NSObject *objc = [[NSObject alloc] init];
        
        /**
         SEL的创建方法
         1、@selector
         2、NSSelectorFromString
         3、sel_registerName
         
         打印结果：
         2022-08-22 11:00:38.472571+0800 runtime2[58864:209755] person:test
         2022-08-22 11:00:38.472890+0800 runtime2[58864:209755] student:test
         2022-08-22 11:00:38.472954+0800 runtime2[58864:209755] SEL1:test SEL2:test
         
         总结：只要函数名称一样，他们的选择器就是一样的
         */
        Person *person = [[Person alloc] init];
        SEL sel1 = NSSelectorFromString(@"test");
        SEL sel2 = sel_registerName("test");
        NSLog(@"SEL1:%s SEL2:%s", sel1, sel2);
    }
    return 0;
}
