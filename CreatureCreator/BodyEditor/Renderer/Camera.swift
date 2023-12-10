//
//  Camera.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import simd

// Camera controller keeps the camera pointing at the target
class CameraController {
    var cameraNode: Node
    var targetNode: Node
    
    init(cameraNode: Node, targetNode: Node) {
        self.cameraNode = cameraNode
        self.targetNode = targetNode
    }
    
    func updateCamera() {
        
    }
}


struct Camera {
    var fov: Float
    var nearPlane: Float
    var farPlane: Float
    
    init(
        fov: Float,
        nearPlane: Float = 0.0001,
        farPlane: Float = 1000
    ) {
        self.fov = fov
        self.nearPlane = nearPlane
        self.farPlane = farPlane
    }
    
    func projectionMatrix(aspectRatio: Float) -> matrix_float4x4 {
        let va_tan = 1.0 / tanf((self.fov * (Float.pi / 180)) * 0.5)
        let ys = va_tan
        let xs = ys / aspectRatio
        let zs = farPlane / (self.farPlane - self.nearPlane)
        
        return simd_float4x4(
            simd_float4(xs, 0,  0, 0),
            simd_float4(0, ys,  0, 0),
            simd_float4(0,  0, zs, 1),
            simd_float4(0,  0, -self.nearPlane * zs, 0)
        )
    }
}

func camera(
    fov: Float,
    nearPlane: Float = 0.0001,
    farPlane: Float = 1000
) -> Camera {
    Camera(
        fov: fov,
        nearPlane: nearPlane,
        farPlane: farPlane
    )
}
