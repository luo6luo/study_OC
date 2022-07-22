//
//  Person.h
//  block0
//
//  Created by lg on 2022/7/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

/// 直接定义block属性
@property (nonatomic, copy) int(^sumBlock)(int a, int b);

@end

NS_ASSUME_NONNULL_END
