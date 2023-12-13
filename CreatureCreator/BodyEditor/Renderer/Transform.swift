//
//  Transform.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import Spatial

extension float4x4 {
    func asTuple() -> ((Float, Float, Float, Float),(Float, Float, Float, Float),(Float, Float, Float, Float),(Float, Float, Float, Float)) {
        return (
            (self[0][0], self[0][1], self[0][2], self[0][3]),
            (self[1][0], self[1][1], self[1][2], self[1][3]),
            (self[2][0], self[2][1], self[2][2], self[2][3]),
            (self[3][0], self[3][1], self[3][2], self[3][3])
        )
    }
}

struct MatrixTransform {
    let matrix: simd_float4x4
    let matrix_inverse: simd_float4x4
    
    init() {
        self.init(matrix: simd_float4x4())
    }
    
    init(matrix: simd_float4x4, matrix_inverse: simd_float4x4) {
        self.matrix = matrix
        self.matrix_inverse = matrix_inverse
    }
    
    init(matrix: simd_float4x4) {
        self.matrix = matrix
        self.matrix_inverse = simd_inverse(matrix)
    }
    
    // Look at
    init(
        eye: simd_float3,
        at: simd_float3,
        up: simd_float3
    ) {
        let z = normalize(at - eye)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        let t = simd_float3(
            x: -dot(x, eye),
            y: -dot(y, eye),
            z: -dot(z, eye)
        )
    
        self.init(matrix: simd_float4x4(
            simd_float4(x.x, y.x, z.x, 0),
            simd_float4(x.y, y.y, z.y, 0),
            simd_float4(x.z, y.z, z.z, 0),
            simd_float4(t.x, t.y, t.z, 1)
        ))
    }
    
    func ffi() -> FFITransform {
        return FFITransform(
            matrix: self.matrix.asTuple(),
            matrix_inverse: self.matrix_inverse.asTuple()
        )
    }
    
    func inverse() -> MatrixTransform {
        MatrixTransform(
            matrix: self.matrix_inverse,
            matrix_inverse: self.matrix
        )
    }
    
    static func *(lhs: MatrixTransform, rhs: MatrixTransform) -> MatrixTransform {
        return MatrixTransform(
            matrix: lhs.matrix * rhs.matrix,
            matrix_inverse: rhs.matrix_inverse * lhs.matrix_inverse
        )
    }
    
    static func *(lhs: MatrixTransform, rhs: SIMD4<Float>) -> SIMD4<Float> {
        return lhs.matrix * rhs
    }
}

func transform(
    position: (Double, Double, Double) = (0, 0, 0),
    rotation: (Double, Double, Double) = (0, 0, 0),
    scale: (Double, Double, Double) = (1, 1, 1)
) -> NodeTransform {
    return NodeTransform(
        position: position,
        rotation: rotation,
        scale: scale
    )
}

struct NodeTransform {
    private let rotationOrder = __SPEulerAngleOrder.xyz
    
    var position: SIMD3<Double>
    var rotation: SIMD3<Double>
    var scale: SIMD3<Double>
    
    init(
        position: (Double, Double, Double) = (0, 0, 0),
        rotation: (Double, Double, Double) = (0, 0, 0),
        scale: (Double, Double, Double) = (1, 1, 1)
    ) {
        self.position = SIMD3(position.0, position.1, position.2)
        self.rotation = SIMD3(rotation.0, rotation.1, rotation.2)
        self.scale = SIMD3(scale.0, scale.1, scale.2)
    }
    
    init(
        affine: AffineTransform3D
    ) {
        self.position = affine.translation.vector
        self.scale = affine.scale.vector
        
        if let rotation = affine.rotation {
            self.rotation = rotation.eulerAngles(order: self.rotationOrder).angles * (180 / Double.pi)
        } else {
            self.rotation = SIMD3(0, 0, 0)
        }
    }
    
    init(
        matrix: MatrixTransform
    ) {
        self.init(affine: AffineTransform3D(matrix.matrix)!)
    }
    
    func affine() -> AffineTransform3D {
        return AffineTransform3D(
            scale: Size3D(vector: scale),
            rotation: Rotation3D(eulerAngles: EulerAngles(angles: rotation * (Double.pi / 180), order: .xyz)),
            translation: Vector3D(vector: position)
        )
    }
    
    func matrix() -> MatrixTransform {
        let transform = self.affine()
        let matrix = transform.matrix4x4
        let matrix_inverse = transform.inverse!.matrix4x4
        
        return MatrixTransform(
            matrix: float4x4(
                SIMD4<Float>(matrix[0]),
                SIMD4<Float>(matrix[1]),
                SIMD4<Float>(matrix[2]),
                SIMD4<Float>(matrix[3])
            ),
            matrix_inverse: float4x4(
                SIMD4<Float>(matrix_inverse[0]),
                SIMD4<Float>(matrix_inverse[1]),
                SIMD4<Float>(matrix_inverse[2]),
                SIMD4<Float>(matrix_inverse[3])
            )
        )
    }
    
}

