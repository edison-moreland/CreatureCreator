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
    
    func ffi() -> FFITransform {
        return FFITransform(
            matrix: self.matrix.asTuple(),
            matrix_inverse: self.matrix_inverse.asTuple()
        )
    }
    
    static func *(lhs: MatrixTransform, rhs: MatrixTransform) -> MatrixTransform {
        return MatrixTransform(
            matrix: lhs.matrix * rhs.matrix,
            matrix_inverse: rhs.matrix_inverse * lhs.matrix_inverse
        )
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

