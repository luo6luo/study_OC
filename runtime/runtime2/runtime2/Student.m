//
//  Student.m
//  runtime2
//
//  Created by lg on 2022/8/22.
//

#import "Student.h"

@implementation Student

+ (void)load
{
    NSLog(@"student:%s", @selector(test));
}

- (void)test
{
    NSLog(@"test");
}

@end
