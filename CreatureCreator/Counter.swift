//
//  Counter.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation

class Counter {
    private let ptr: UnsafeMutableRawPointer
    
    init() {
        ptr = counter_make()
    }
    
    deinit {
        counter_free(ptr)
    }
    
    func next() -> UInt64 {
        counter_next(ptr)
    }
}
