//
//  main.m
//  block2
//
//  Created by lg on 2022/5/23.
//

#import <Foundation/Foundation.h>

# pragma mark

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        int age = 10;
        
        void (^block)(void) = ^{
            NSLog(@"age - %d", age);
        };
        
        age = 20;
        block();
    }
    return 0;
}
