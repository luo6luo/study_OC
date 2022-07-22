//
//  Person.m
//  block0
//
//  Created by lg on 2022/7/22.
//

#import "Person.h"

@implementation Person

- (void)dealloc
{
    NSLog(@"Person -- dealloc");
}

- (instancetype)init
{
    if (self = [super init]) {
        self.sumBlock = ^(int a, int b) {
            NSLog(@"sumBlock");
            return a + b;
        };
    }
    return self;
}

@end
