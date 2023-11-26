//
//  Surfaces.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import MetalKit

class SurfacePipeline {
    private let ptr: UnsafeMutableRawPointer
    
    init(_ device: MTLDevice) {
        let device_ptr = Unmanaged.passUnretained(device).toOpaque()
        
        self.ptr = surface_pipeline_make(device_ptr)
    }
    
    deinit {
        surface_pipeline_free(self.ptr)
    }
    
    func draw(_ transform: Transform, ellipsoid: (Float, Float, Float)) {
        surface_pipeline_draw_ellipsoid(self.ptr, transform, Ellipsoid(size: ellipsoid))
    }
    
    func commit(_ encoder: MTLRenderCommandEncoder) {
        let encoder_ptr = Unmanaged.passUnretained(encoder).toOpaque()
        
        surface_pipeline_commit(self.ptr, encoder_ptr)
    }
}
