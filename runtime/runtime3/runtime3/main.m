//
//  main.m
//  runtime3
//
//  Created by lg on 2022/9/27.
//
//  cache_t cache 方法缓存
//  参考资料：
//  1、官方文档：https://developer.apple.com/documentation/objectivec/objective-c_runtime/objc_cache?language=objc
//  2、cache_t分析：https://tech.meituan.com/2015/08/12/deep-understanding-object-c-of-method-caching.html

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /**
         一、官方文档 objc_cache
         struct objc_cache
         {
            unsigned int mask;
            unsigned int occupied;
            Method buckets[1];
         };
         
         官方解读：
         objc_cache: 为了限制频繁的访问定义的方法列表进行执行线性搜索的需要（这种操作会大大降低方法查找的速度），
                     Objective-C运行时函数在objc_cache数据结构中存储最近调用定义的方法的指针。
         mask: 一个整数，指定分配的buckets总数（减1）。
               在方法查找期间，Objective-C运行时使用此字段来确定对buckets数组进行线性搜索的索引。
               使用逻辑AND操作（index =（mask&selector））将指向方法选择器的指针屏蔽到此字段。这是一个简单的哈希算法。
         occupied: 一个整数，指定已占用的buckets总数。
         buckets: 指向方法数据结构的指针数组。此数组最多只能包含mask+1项。
                  请注意，指针可能为NULL，表示缓存bucket未被占用，并且被占用的bucket可能不连续。此阵列可能会随时间增长。
         
         ----------------------------------------------------------------
         
         二、runtime - cache_t
         cache_t 是官网 objc_cache 对应的runtime源码的底层结构，作用是方法缓存。
         注意：源码的分析是分很多平台架构的，这里只分析：CACHE_MASK_STORAGE == CACHE_MASK_STORAGE_OUTLINED，
              其他原理是相同的。
         
         // 简化 cache_t 后
         struct cache_t {
         private:
             explicit_atomic<uintptr_t> _bucketsAndMaybeMask;
             union {
                 struct {
                     explicit_atomic<mask_t>    _maybeMask;
                     uint16_t                   _occupied;
                 };
                 explicit_atomic<preopt_cache_t *> _originalPreoptCache;
             };
         ...
             mask_t mask() const;
         ...
         public:
             struct bucket_t *buckets() const;
             mask_t occupied() const;
             void insert(SEL sel, IMP imp, id receiver);
         ...
        
         }
         
         其中非常重要的三个点：
         mask_t mask() const;
         struct bucket_t *buckets() const;
         mask_t occupied() const;
         
         ----------------------------------------------------------------
         
         三、explicit_atomic 分析
         
         在解释cache_t重要点之前，需要认识下
         1、explicit_atomic 的 load 方法
         2、memory_order_relaxed 操作符
         
         struct explicit_atomic : public std::atomic<T> {
             explicit explicit_atomic(T initial) noexcept : std::atomic<T>(std::move(initial)) {}
             operator T() const = delete;
             
             T load(std::memory_order order) const noexcept {
                 return std::atomic<T>::load(order);
             }
             void store(T desired, std::memory_order order) noexcept {
                 std::atomic<T>::store(desired, order);
             }
             
             // Convert a normal pointer to an atomic pointer. This is a
             // somewhat dodgy thing to do, but if the atomic type is lock
             // free and the same size as the non-atomic type, we know the
             // representations are the same, and the compiler generates good
             // code.
             static explicit_atomic<T> *from_pointer(T *ptr) {
                 static_assert(sizeof(explicit_atomic<T> *) == sizeof(T *),
                               "Size of atomic must match size of original");
                 explicit_atomic<T> *atomic = (explicit_atomic<T> *)ptr;
                 ASSERT(atomic->is_lock_free());
                 return atomic;
             }
         };
         
         官方解释：std:：atomic的版本，不允许与包装类型进行隐式转换，并且需要将显式内存顺序传递给load（）和store（）。
    
         总结：
         · explicit_atomic结构体作用，是一种数据类型操作转换
         · memory_order_relaxed：宽松操作：只保证当前操作的原子性，不考虑线程间的同步，其他线程可能读到新值，也可能读到旧值。
         
         ----------------------------------------------------------------

         四、mask buckets occupied 详解
         
         // 获取 mask
         mask_t cache_t::mask() const
         {
             return _maybeMask.load(memory_order_relaxed);
         }
         
         解析：_maybeMask 内容其实就是 mask 内容，mask 类型是 mask_t。
         
    
         // 获取 buckets
         static constexpr uintptr_t bucketsMask = ~0ul;
         struct bucket_t *cache_t::buckets() const
         {
             uintptr_t addr = _bucketsAndMaybeMask.load(memory_order_relaxed);
             return (bucket_t *)(addr & bucketsMask);
         }
         
         解释：_bucketsAndMaybeMask 类似 isa，它存储的不只是 buckets 的地址，还包含很多其他信息，这里利用 bucketsMask 进行位运算，
              去取对应的 buckets 地址。
         
         // 获取 occupied
         void cache_t::initializeToPreoptCacheInDisguise(const preopt_cache_t *cache)
         {
             ...
             _occupied = cache->occupied;
         }
         
         mask_t cache_t::occupied() const
         {
             return _occupied;
         }
         
         解释：所以 occupied 就是 _occupied，类型是 mask_t。
         
         总结：这样看，其实cache_t结构又可以简化
         struct cache_t {
         ...
             mask_t mask() const;
             struct bucket_t *buckets() const;
             mask_t occupied() const;
         
             void insert(SEL sel, IMP imp, id receiver);
         ...
         }
         
         
         ----------------------------------------------------------------
         
         五、buckets 详解
         
         struct bucket_t {
         private:
             // IMP-first is better for arm64e ptrauth and no worse for arm64.
             // SEL-first is better for armv7* and i386 and x86_64.
         #if __arm64__
             explicit_atomic<uintptr_t> _imp;
             explicit_atomic<SEL> _sel;
         #else
             explicit_atomic<SEL> _sel;
             explicit_atomic<uintptr_t> _imp;
         #endif
         }
         
         bucket_t中，主要就是存储的_imp、_sel，这相当于一个key-value的组合。
         buckets是一个散列表，存放很多 bucket_t。
         方法底层是 method_t 结构，通过设置 key = SEL name，value = 方法实现地址imp，bucket_t实际就是存储一个method_t，
         生成一个bucket_t存储在散列表中。
         
         * 问题1：怎么查询缓存方法
           一般查找方法：实例对象 (isa)-> 类对象 → method_list_t中查找对应方法 (找到)→ 调用方法
                                                  ↑            ↓(未找到)
                                                  ↑    通过 superClass 指针找到父类
                                                  ↑            ↓
                                                   ← ← ← ← ← ← ←
         如果每次调用方法都这么查询，太消耗性能了，所以每次调用方法，是先去 buckets 中查询，有就直接根据地址调用方法，避免循环查找。
         如果 buckets 中没有存储，则再去类的方法列表遍历查询。然后将查询的方法存放到散列表中。
         
         * 问题2：散列表是怎么查询方法的
           如果 buckets 存储的内容太多，通过遍历方法查询也很费性能，所以散列表的存储查询是经过算法优化的，下面详解原理。
         
         散列表结构如下，它其实有个索引，每个缓存method对应一个index，index = mask & selector。
         index  method
         -----|----------
          0   | bucket_t
         -----|----------
          1   | bucket_t  -> @selector(test)
         -----|----------
          2   | bucket_t
         -----|----------
         ...  | ...
         -----|----------
          9   | bucket_t
         -----|----------

         
         eg: 假设现在 buckets 中有10条数据，当前 mask = 9，occupied = 0。
             现将一个 void test() {} 方法进行缓存，假设它将存入index = 1的位置。
         · 存:
           1、查询到未缓存 test 方法，现缓存 test 方法。
           2、将 test 方法生成一个 bucket_t，_sel = @select(test)，_imp = IMP(方法实现地址)。
           3、生成索引 index = 9 & @selector(test)，假设获得的结果 index = 1。
             注意：一个数字 & mask，那结果一定是 <= mask。而所有地址，其实都是一个十六位数字。
             eg:  0101 0101 = @selector(test)地址
                & 0000 1001 = 9
             -------------------
                  0000 0001 = 1
            4、将生成的 test bucket_t 存入 index = 1 的位置。
            5、存入后，occupied = 1，mask = 9，buckets 中有一个数据，其他位置是 NULL。所以散列表也是不连续的存储数据。
         
         · 取:
           1、生成索引 index = 9 & @selector(test) = 1。
           2、根据 index，去取 bucket_t = buckets[index]。
           3、获取到 test方法实现地址 = bucket_t的_imp。
         
         * 问题3：如果存/取时候，index是相同怎么处理
           具体的操作看 void insert(SEL sel, IMP imp, id receiver) 方法实现
         
         void cache_t::insert(SEL sel, IMP imp, id receiver)
         {
             ....
         
             bucket_t *b = buckets(); // 获取散列表
             mask_t m = capacity - 1; // capacity 翻译过来是"容量"，所以 m 应该是 mask，即 buckets 的容量 - 1。
                                      // 因为buckets会在使用过程中扩容，所以容量不是固定不变的。
             mask_t begin = cache_hash(sel, m); // 获取index
             mask_t i = begin;

             // Scan for the first unused slot(槽点) and insert there.
             // There is guaranteed(保证) to be an empty slot.
             do {
                 if (fastpath(b[i].sel() == 0)) { // 根据 i 获取bucket_t，取其中的sel，sel不存在
                     incrementOccupied(); // Occupied++
                     b[i].set<Atomic, Encoded>(b, sel, imp, cls()); // 将方法存入buckets的第i个位置
                     return;
                 }
                 if (b[i].sel() == sel) { // ..sel() == sel，该方法已经存在 i 位置了
                     // The entry was added to the cache by some other thread
                     // before we grabbed the cacheUpdateLock.
                     return;
                 }
             } while (fastpath((i = cache_next(i, m)) != begin));

             // 如果根据 i 取值，如果该位置已经存了其他值，则根据 cache_next 取下一个 i
             // 直到确保 i 为空，获取 i 已经存了该值
         
             ....
         }
         
         // 实际是 index 的生成规则
         static inline mask_t cache_hash(SEL sel, mask_t mask)
         {
             uintptr_t value = (uintptr_t)sel;
         #if CONFIG_USE_PREOPT_CACHES
             value ^= value >> 7;
         #endif
             return (mask_t)(value & mask);
         }
         
         // 取下一个index
         // i == 0，i = mask，从最大开始遍历
         // i != 0，i -= 1，
         static inline mask_t cache_next(mask_t i, mask_t mask) {
             return i ? i-1 : mask;
         }
         
         ----------------------------------------------------------------
         
         */
    }
    return 0;
}
