//
//  Transform.swift
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

import Foundation

func transform(
    position: (Float, Float, Float) = (0, 0, 0),
    rotation: (Float, Float, Float) = (0, 0, 0),
    scale: (Float, Float, Float) = (1, 1, 1)
) -> Transform {
    Transform(position: position, rotation: rotation, scale: scale)
}
