//
//  Transform.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation
import SceneKit

extension SCNMatrix4 {
    func asFFITransform() -> FFITransform {
        return FFITransform(
            matrix: simd_float4x4(self),
            matrix_inverse: simd_float4x4(SCNMatrix4Invert(self)))
    }
}
