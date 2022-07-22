//
//  Person.h
//  block7
//
//  Created by lg on 2022/7/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic, assign) int age;
@property (nonatomic, copy) void(^block)(void);

@end

NS_ASSUME_NONNULL_END
