//
//  Surfaces.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import MetalKit

enum Surface {
    case Ellipsoid(Float, Float, Float)
}

func ellipsoid(_ x: Float, _ y: Float, _ z: Float) -> Surface {
    .Ellipsoid(x, y, z)
}

class SurfacePipeline {
    private let ptr: UnsafeMutableRawPointer
    
    init(_ device: MTLDevice) {
        let device_ptr = Unmanaged.passUnretained(device).toOpaque()
        
        self.ptr = surface_pipeline_make(device_ptr)
    }
    
    deinit {
        surface_pipeline_free(self.ptr)
    }
    
    func begin() {
        surface_pipeline_begin(self.ptr)
    }
    
    func end() {
        surface_pipeline_end(self.ptr)
    }
    
    func draw(_ transform: MatrixTransform, _ surface: Surface) {
        switch surface {
        case .Ellipsoid(let x, let y, let z):
            surface_pipeline_draw_ellipsoid(self.ptr, transform.ffi(), Ellipsoid(size: (x, y, z)))
        }
        
    }
    
    func encode(_ encoder: MTLRenderCommandEncoder) {
        let encoder_ptr = Unmanaged.passUnretained(encoder).toOpaque()
        
        surface_pipeline_encode(self.ptr, encoder_ptr)
    }
}
