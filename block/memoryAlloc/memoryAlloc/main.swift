//
//  main.swift
//  memoryAlloc
//
//  Created by lg on 2022/7/15.
//
//  内存分配管理
//  本节专门针对内存区域，分配管理做个额外小结

import Foundation
import Cocoa

/// 测试区域地址
func testMemoryArea()
{
    let a = 10
    let b = 20
    let person = Person()
    
    print(
        String(format: "%@", a),
        String(format: "%p", b),
        String(format: "%p", person),
        separator: "\n"
    )
}
testMemoryArea();
