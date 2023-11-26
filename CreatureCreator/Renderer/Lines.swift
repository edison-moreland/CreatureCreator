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
    
    init(_ device: MTLDevice) {
        let device_ptr = Unmanaged.passUnretained(device).toOpaque()
        
        self.ptr = line_pipeline_make(device_ptr)
    }
    
    deinit {
        line_pipeline_free(self.ptr)
    }
    
    func draw(_ transform: Transform, _ line: Line) {
        line_pipeline_draw(self.ptr, transform, line)
    }
    
    func commit(_ encoder: MTLRenderCommandEncoder) {
        let encoder_ptr = Unmanaged.passUnretained(encoder).toOpaque()
        
        line_pipeline_commit(self.ptr, encoder_ptr)
    }
}

func line(
    length: Float,
    color: (Float, Float, Float) = (0, 0, 0),
    thickness: Float = 0.1,
    dash_size: Float = 0
) -> Line {
    Line(
        style: 0,
        color: color,
        size: length,
        thickness: thickness,
        dash_size: dash_size
    )
}

func arrow(
    length: Float,
    color: (Float, Float, Float) = (0, 0, 0),
    thickness: Float = 0.1,
    dash_size: Float = 0
) -> Line {
    Line(
        style: 1,
        color: color,
        size: length,
        thickness: thickness,
        dash_size: dash_size
    )
}

func circle(
    diameter: Float,
    color: (Float, Float, Float) = (0, 0, 0),
    thickness: Float = 0.1,
    dash_size: Float = 0
) -> Line {
    Line(
        style: 2,
        color: color,
        size: diameter,
        thickness: thickness,
        dash_size: dash_size
    )
}
