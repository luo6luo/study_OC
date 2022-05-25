//
//  main.m
//  block1
//
//  Created by lg on 2022/5/19.
//

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        void (^block)(void) = ^{
            NSLog(@"block");
        };
        
        block();
    }
    return 0;
}
