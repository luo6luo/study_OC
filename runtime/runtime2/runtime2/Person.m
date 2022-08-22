//
//  Person.m
//  runtime2
//
//  Created by lg on 2022/8/22.
//

#import "Person.h"

@implementation Person

+ (void)load
{
    NSLog(@"person:%s", @selector(test));
}

- (void)test
{
    NSLog(@"test");
}

@end
