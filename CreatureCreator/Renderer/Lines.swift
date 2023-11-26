//
//  Lines.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import MetalKit

class LinePipeline {
    private let ptr: UnsafeMutableRawPointer
    
    init(device: MTLDevice) {
        let device_ptr = Unmanaged.passUnretained(device).toOpaque()
        
        self.ptr = line_pipeline_make(device_ptr)
    }
    
    deinit {
        line_pipeline_free(self.ptr)
    }
    
    func draw(transform: Transform, line: Line) {
        line_pipeline_draw(self.ptr, transform, line)
    }
    
    func commit(encoder: MTLRenderCommandEncoder) {
        let encoder_ptr = Unmanaged.passUnretained(encoder).toOpaque()
        
        line_pipeline_commit(self.ptr, encoder_ptr)
    }
}
